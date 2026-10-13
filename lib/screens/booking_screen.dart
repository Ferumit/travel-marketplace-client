import '../theme/app_colors.dart';
import 'package:explora_app/models/user_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/partner_models.dart';
import '../models/booking_models.dart';
import '../models/tour_models.dart' as tour;
import '../repository/firestore_data_repository.dart';
import '../route_builder/route_builder_controller.dart';
import '../route_builder/route_calculator.dart';
import '../services/auth_service.dart';
import '../widgets/partner_profile_sheet.dart';
import '../theme/theme.dart';
import '../widgets/service_selection_sheet.dart';
import '../l10n/app_localizations.dart';
import '../services/payment_service.dart';

class BookingScreen extends StatefulWidget {
  final RouteBuilderController? controller;

  /// Non-null when opening from a standard (catalogue) route.
  final tour.Route? route;

  const BookingScreen({super.key, this.controller, this.route});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _people = 2;

  int _pointCount = 2;
  List<DateTime> _selectedDates = [];
  List<TimeOfDay> _selectedTimes = [];

  final TextEditingController _routeNameController = TextEditingController();
  ServiceRole? _selectedVehicleRole;
  ServiceRole? _selectedGuideRole;

  List<PartnerProfile> _allDrivers = [];
  bool _isLoadingDrivers = true;
  String? _selectedDriverId;

  List<PartnerProfile> _allGuides = [];
  bool _isLoadingGuides = true;
  String? _selectedGuideId;

  // New pricing-related states
  String _selectedRoadType = 'Асфальт';
  bool _isNightTrip = false;
  bool _needInsurance = false;

  // Guard against double-tap during Firestore save
  bool _isSaving = false;

  // Компаньоны, добавленные при создании маршрута
  final List<CompanionInfo> _invitedCompanions = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pointCount = widget.controller?.waypoints.length ?? 2;

    var currentDt = DateTime(
      now.year, now.month, now.day,
      now.hour < 20 ? now.hour + 1 : 8, 0,
    );
    
    _selectedDates = [];
    _selectedTimes = [];
    final waypoints = widget.controller?.waypoints;

    for (int i = 0; i < _pointCount; i++) {
      _selectedDates.add(currentDt);
      _selectedTimes.add(TimeOfDay(hour: currentDt.hour, minute: currentDt.minute));
      
      if (waypoints != null && i < waypoints.length - 1) {
        final w1 = waypoints[i];
        final w2 = waypoints[i + 1];
        // Straight-line distance * 1.3 (approx road factor)
        final distKm = RouteCalculator.calculateDistance(
          w1.latitude, w1.longitude,
          w2.latitude, w2.longitude,
        ) * 1.3;
        
        // Travel time based on 50 km/h avg speed + 30 mins stop per waypoint
        final travelMins = ((distKm / 50.0) * 60).round();
        currentDt = currentDt.add(Duration(minutes: travelMins + 30));
      } else if (waypoints == null && widget.route != null && i == 0) {
        // If booking a predefined route, estimate the finish time
        // based on the route's duration.
        final days = widget.route!.duration;
        if (days <= 1) {
          currentDt = currentDt.add(const Duration(hours: 8));
        } else {
          currentDt = currentDt.add(Duration(days: days - 1, hours: 8));
        }
      }
    }

    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final futures = await Future.wait([
        FirestoreDataRepository.instance.getDrivers(),
        FirestoreDataRepository.instance.getGuides(),
      ]);
      if (mounted) {
        setState(() {
          _allDrivers = futures[0];
          _isLoadingDrivers = false;

          _allGuides = futures[1];
          _isLoadingGuides = false;
        });
        _updateSelectedDriver();
        _updateSelectedGuide();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDrivers = false;
          _isLoadingGuides = false;
        });
      }
    }
  }

  void _updateSelectedDriver() {
    final available = _filteredDrivers;
    if (available.isNotEmpty) {
      if (!_selectedDriverIdValid(available)) {
        _selectedDriverId = available.first.id;
      }
    } else {
      _selectedDriverId = null;
    }
  }

  void _updateSelectedGuide() {
    final available = _filteredGuides;
    if (available.isNotEmpty) {
      if (!_selectedGuideIdValid(available)) {
        _selectedGuideId = available.first.id;
      }
    } else {
      _selectedGuideId = null;
    }
  }

  bool _selectedDriverIdValid(List<PartnerProfile> available) {
    return available.any((d) => d.id == _selectedDriverId);
  }

  bool _selectedGuideIdValid(List<PartnerProfile> available) {
    return available.any((g) => g.id == _selectedGuideId);
  }

  List<PartnerProfile> get _filteredDrivers {
    if (_selectedVehicleRole == null) return [];

    final filtered = _allDrivers.where((d) {
      // ServiceRole names are identical to PartnerRole names — direct mapping
      if (_selectedVehicleRole == ServiceRole.suvDriver) {
        return d.role == PartnerRole.suvDriver;
      } else if (_selectedVehicleRole == ServiceRole.busDriver) {
        return d.role == PartnerRole.busDriver;
      } else if (_selectedVehicleRole == ServiceRole.minibusDriver) {
        return d.role == PartnerRole.minibusDriver;
      } else if (_selectedVehicleRole == ServiceRole.minivanDriver) {
        return d.role == PartnerRole.minivanDriver;
      }
      return d.role.isDriver;
    }).toList();

    filtered.sort((a, b) => b.rating.compareTo(a.rating));
    return filtered;
  }

  List<PartnerProfile> get _filteredGuides {
    if (_selectedGuideRole == null) return [];
    final wantCity = _selectedGuideRole == ServiceRole.cityGuide;
    final filtered = _allGuides
        .where(
          (g) => wantCity
              ? g.role == PartnerRole.cityGuide
              : g.role == PartnerRole.guide,
        )
        .toList();
    filtered.sort((a, b) => b.rating.compareTo(a.rating));
    return filtered;
  }

  /// Максимальное количество человек в туре. Не ограничиваем вместимостью
  /// одной машины, так как мы теперь автоматически масштабируем (заказываем несколько машин).
  int get _maxPeople {
    if (widget.route != null) {
      return widget.route!.maxGroupSize;
    }
    return 10;
  }

  void _checkAndClampPeople() {
    final max = _maxPeople;
    if (_people > max) {
      setState(() {
        _people = max;
      });
    }
  }

  int get _calculatedHours {
    if (_selectedDates.isEmpty) return 24;
    final start = DateTime(
      _selectedDates.first.year,
      _selectedDates.first.month,
      _selectedDates.first.day,
      _selectedTimes.first.hour,
      _selectedTimes.first.minute,
    );
    final end = DateTime(
      _selectedDates.last.year,
      _selectedDates.last.month,
      _selectedDates.last.day,
      _selectedTimes.last.hour,
      _selectedTimes.last.minute,
    );
    final diffHours = end.difference(start).inHours;
    return diffHours > 0 ? diffHours : 24;
  }

  int get _calculatedDays {
    final diffHours = _calculatedHours;
    if (diffHours <= 16) return 1; // up to 16h counts as 1 day (was 12h — caused double-pricing for long day trips)
    if (diffHours < 36) return 2;
    if (diffHours < 60) return 3;
    if (diffHours < 84) return 4;
    return (diffHours / 24).ceil();
  }

  Map<String, dynamic> get _pricingDetails {
    final distance = widget.controller?.routeDistanceKm ?? 20.0;
    final int D = _calculatedDays;
    final int H = _calculatedHours;

    // Блок А: Транспорт (P_transport)
    double pTransport = 0.0;
    double transportBase = 0.0;
    double lExtCost = 0.0;
    double driverStay = 0.0;

    double roadMultiplier = 1.0;
    if (_selectedRoadType == 'Гравий/Грунт') {
      roadMultiplier = 1.3;
    } else if (_selectedRoadType == 'Жесткий Offroad') {
      roadMultiplier = _selectedVehicleRole == ServiceRole.suvDriver
          ? 1.6
          : 1.3;
    }
    if (_isNightTrip) roadMultiplier *= 1.3;

    if (_selectedDriverId != null) {
      final driver = _allDrivers
          .where((d) => d.id == _selectedDriverId)
          .firstOrNull;

      // Drivers are paid per km, not per day.
      final kmRate = driver?.pricePerKm ?? 300.0; // ₸ per km
      final dailyMileageLimit = driver?.dailyMileageLimit ?? 300;
      final overagePricePerKm = driver?.overagePricePerKm ?? 300.0;
      final driverStayPerDay = driver?.driverStayPerDay ?? 15000.0;
      final capacity = driver?.vehicleCapacity ?? 4;

      // Рассчитываем количество необходимых машин
      int availableSeats = capacity - 1;
      if (_selectedGuideId != null) availableSeats -= 1;
      if (availableSeats < 1) availableSeats = 1;

      int numCars = (_people / availableSeats).ceil();
      if (numCars < 1) numCars = 1;

      // Bus with >500 km or >9h trip requires a 2nd driver (+25%)
      if (_selectedVehicleRole == ServiceRole.busDriver &&
          (distance > 500 || H > 9)) {
        roadMultiplier *= 1.25;
      }

      // Base: rate per km × total distance × road/night multiplier
      transportBase = kmRate * distance * roadMultiplier * numCars;

      // Overage: km beyond daily limit across all days
      final totalLimit = (D * dailyMileageLimit).toDouble();
      final lExt = distance > totalLimit ? (distance - totalLimit) : 0.0;
      lExtCost = lExt * overagePricePerKm * numCars;

      // Driver accommodation for multi-day trips
      driverStay = D > 1 ? (D - 1) * driverStayPerDay * numCars : 0.0;

      pTransport = transportBase + lExtCost + driverStay;
    }

    // Блок Б: Сервис/Гиды (P_service)
    double pService = 0.0;
    double kTime = 1.0;

    if (_selectedDates.isNotEmpty && _selectedTimes.first.hour >= 18) {
      kTime = 1.5;
    }

    if (_selectedGuideId != null) {
      final guide = _allGuides
          .where((g) => g.id == _selectedGuideId)
          .firstOrNull;
      final gRate = guide?.pricePerDay ?? 30000.0;
      // G_rate * D * K_time * K_lang
      pService = gRate * D * kTime * 1.0;
    }

    // Блок В: Фиксированные сборы (P_fixed)
    final ecoPerson = 1000.0;
    final ecoAuto = 2000.0;
    final sIns = _needInsurance ? 3000.0 : 0.0;

    double pFixed = (ecoPerson * _people) + ecoAuto + (sIns * _people);

    // Итого (K_margin = 1.15)
    final kMargin = 1.15;
    double totalPrice = (pTransport + pService) * kMargin + pFixed;

    // Минимальная гарантия
    if (totalPrice < 500) {
      totalPrice = 500;
    }

    return {
      'pTransport': pTransport,
      'transportBase': transportBase,
      'lExtCost': lExtCost,
      'driverStayCost': driverStay,
      'pService': pService,
      'kTime': kTime,
      'pFixed': pFixed,
      'ecoTax': (ecoPerson * _people) + ecoAuto,
      'insuranceCost': sIns * _people,
      'totalPrice': totalPrice,
      'days': D,
      'margin': kMargin,
    };
  }

  int get _price => (_pricingDetails['totalPrice'] as double).toInt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.go('/'),
        ),
        title: Text(l10n.bookingDetailsTitle),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _buildSectionTitle(l10n.routeNameLabelOptional),
                _buildRouteNameInput(l10n),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.routeDatesLabel),
                for (int i = 0; i < _pointCount; i++)
                  _buildDateSelector(i, l10n),
                _buildFinishRow(l10n),
                const SizedBox(height: 12),

                _buildSectionTitle(l10n.peopleCountLabel),
                _buildPeopleCounter(l10n),
                const SizedBox(height: 16),

                // ── Компаньоны — только когда пассажиров > 1 ──
                if (_people > 1) ...[
                  _buildSectionTitle('ПРИГЛАШЁННЫЕ КЛИЕНТЫ'),
                  _buildCompanionInviteSection(),
                  const SizedBox(height: 24),
                ],

                _buildSectionTitle(l10n.transportOptionalLabel),
                _buildServiceSelection(
                  label: l10n.selectTransportLabel,
                  l10n: l10n,
                  icon: LucideIcons.car,
                  selectedRole: _selectedVehicleRole,
                  isGuide: false,
                  onSelect: (role) {
                    setState(() {
                      _selectedVehicleRole = role;
                      _updateSelectedDriver();
                      _checkAndClampPeople();
                    });
                  },
                  onClear: () {
                    setState(() {
                      _selectedVehicleRole = null;
                      _selectedDriverId = null;
                      _checkAndClampPeople();
                    });
                  },
                ),
                if (_selectedVehicleRole != null) ...[
                  const SizedBox(height: 16),
                  _buildDriverSelection(l10n),
                  const SizedBox(height: 16),
                  _buildSectionTitle(l10n.roadTypeConditionsLabel),
                  _buildRoadTypeSelectors(l10n),
                ],
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.guideOptionalLabel),
                _buildServiceSelection(
                  label: l10n.selectGuideLabel,
                  l10n: l10n,
                  icon: LucideIcons.user,
                  selectedRole: _selectedGuideRole,
                  isGuide: true,
                  onSelect: (role) {
                    setState(() {
                      _selectedGuideRole = role;
                      _updateSelectedGuide();
                      _checkAndClampPeople();
                    });
                  },
                  onClear: () {
                    setState(() {
                      _selectedGuideRole = null;
                      _selectedGuideId = null;
                      _checkAndClampPeople();
                    });
                  },
                ),
                if (_selectedGuideRole != null) ...[
                  const SizedBox(height: 16),
                  _buildGuideSelection(l10n),
                ],
                // Страховка показывается только для готовых туров
                if (widget.controller == null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(l10n.additionalLabel),
                  _buildInsuranceSelector(l10n),
                ],
              ],
            ),
          ),

          // Footer - Detailed Receipt
          Container(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildReceipt(l10n),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            try {
                              final userId =
                                  AuthService.instance.currentFirebaseUser?.uid;

                              if (userId == null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.errorUserNotFound),
                                    backgroundColor: context.errorColor,
                                  ),
                                );
                                return;
                              }

                              // ── Pre-check: no duplicate active trips ─────
                              final alreadyHas = await FirestoreDataRepository
                                  .instance
                                  .hasActiveTrips(userId);
                              if (alreadyHas) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.errorActiveTripExists),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }

                              // ── Resolve partner names ────────────────────
                              final selectedGuide = _allGuides
                                  .where((g) => g.id == _selectedGuideId)
                                  .firstOrNull;
                              final selectedDriver = _allDrivers
                                  .where((d) => d.id == _selectedDriverId)
                                  .firstOrNull;

                              // ── Driver required for both flows ───────────
                              if (_selectedDriverId == null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.errorSelectVehicle),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }

                              // ── Soft guard: check partner availability ────
                              final driverFree = await FirestoreDataRepository
                                  .instance
                                  .isPartnerAvailable(_selectedDriverId!);
                              if (!driverFree) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Выбранный водитель уже занят на другом маршруте. Пожалуйста, выберите другого.',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }
                              if (_selectedGuideId != null) {
                                final guideFree = await FirestoreDataRepository
                                    .instance
                                    .isPartnerAvailable(_selectedGuideId!);
                                if (!guideFree) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Выбранный гид уже занят на другом маршруте. Пожалуйста, выберите другого.',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  return;
                                }
                              }

                              final waypointDates = <String>[];
                              for (int i = 0; i < _pointCount; i++) {
                                final dt = DateTime(
                                  _selectedDates[i].year,
                                  _selectedDates[i].month,
                                  _selectedDates[i].day,
                                  _selectedTimes[i].hour,
                                  _selectedTimes[i].minute,
                                );
                                waypointDates.add(dt.toIso8601String());
                              }

                              final details = _pricingDetails;
                              final driverEarning =
                                  details['pTransport'] as double;
                              final guideEarning =
                                  details['pService'] as double;

                              if (widget.controller != null) {
                                // ── Custom-route flow ────────────────────────
                                final savedBooking = await widget.controller!.saveRoute(
                                  waypointDates: waypointDates,
                                  participants: _people,
                                  guideId: _selectedGuideId,
                                  guideName: selectedGuide?.fullName,
                                  driverId: _selectedDriverId,
                                  driverName: selectedDriver != null
                                      ? '${selectedDriver.fullName} — ${selectedDriver.vehicleModel}'
                                      : null,
                                  customRouteTitle:
                                      _routeNameController.text
                                          .trim()
                                          .isNotEmpty
                                      ? _routeNameController.text.trim()
                                      : null,
                                  driverEarning: driverEarning,
                                  guideEarning: guideEarning,
                                  companions: _invitedCompanions,
                                );

                                // ── Диалог подтверждения оплаты (custom route) ─
                                if (!context.mounted) return;
                                final customTotal = savedBooking.totalPrice;
                                final customTransport = (details['pTransport'] as double);
                                final customService = (details['pService'] as double);
                                final customEco = (details['ecoTax'] as double);
                                final customInsurance = (details['insuranceCost'] as double);
                                String fmtMoney(double v) => v.toInt().toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

                                final bool? customConfirmed = await showModalBottomSheet<bool>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(ctx).scaffoldBackgroundColor,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40, height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          width: 64, height: 64,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF34C759), Color(0xFF30D158)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(color: const Color(0xFF34C759).withValues(alpha: 0.3),
                                                blurRadius: 16, offset: const Offset(0, 6)),
                                            ],
                                          ),
                                          child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 30),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Подтверждение оплаты',
                                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('Маршрут: ${savedBooking.routeTitle}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              if (customTransport > 0) ...[
                                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                  const Text('🚗 Транспорт', style: TextStyle(fontSize: 14)),
                                                  Text('${fmtMoney(customTransport)} ₸', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                ]),
                                                const SizedBox(height: 8),
                                              ],
                                              if (customService > 0) ...[
                                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                  const Text('🧑‍🏫 Гид', style: TextStyle(fontSize: 14)),
                                                  Text('${fmtMoney(customService)} ₸', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                ]),
                                                const SizedBox(height: 8),
                                              ],
                                              if (customEco > 0) ...[
                                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                  const Text('🌿 Экосбор', style: TextStyle(fontSize: 14)),
                                                  Text('${fmtMoney(customEco)} ₸', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                ]),
                                                const SizedBox(height: 8),
                                              ],
                                              if (customInsurance > 0) ...[
                                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                  const Text('🛡️ Страховка', style: TextStyle(fontSize: 14)),
                                                  Text('${fmtMoney(customInsurance)} ₸', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                ]),
                                                const SizedBox(height: 8),
                                              ],
                                              Divider(height: 1, color: Colors.grey.shade300),
                                              const SizedBox(height: 12),
                                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                const Text('Итого к оплате',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                Text('${fmtMoney(customTotal)} ₸',
                                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF34C759))),
                                              ]),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.science_outlined, size: 14, color: Colors.amber),
                                              SizedBox(width: 6),
                                              Text('Тестовый режим оплаты (Freedom Pay)',
                                                style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton.icon(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            icon: const Icon(Icons.lock_rounded, size: 18),
                                            label: const Text('Оплатить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF34C759),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Отмена', style: TextStyle(fontSize: 15, color: Colors.grey)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (customConfirmed != true) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Оплата отменена. Бронь сохранена.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  context.go('/active_trips');
                                  return;
                                }

                                // ── Freedom Pay для кастомного маршрута ─────
                                if (!context.mounted) return;
                                final customPaymentService = PaymentService();
                                final bool customSuccess = await customPaymentService.startPaymentFlow(
                                  context: context,
                                  amount: customTotal,
                                  description: 'Оплата маршрута: ${savedBooking.routeTitle}',
                                  routeId: savedBooking.id,
                                  userId: userId,
                                );
                                if (!customSuccess) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Оплата не прошла. Бронь сохранена, но не оплачена.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  // Navigate anyway so user sees their trip
                                  if (!context.mounted) return;
                                  context.go('/active_trips');
                                  return;
                                }
                              } else {
                                // ── Standard (catalogue) route flow ──────────
                                final tour.Route? route = widget.route;
                                final routeTitle =
                                    _routeNameController.text.trim().isNotEmpty
                                    ? _routeNameController.text.trim()
                                    : (route?.title ?? 'Маршрут');

                                final bookingId =
                                    'booking_${DateTime.now().millisecondsSinceEpoch}';
                                final tripId =
                                    'trip_${DateTime.now().millisecondsSinceEpoch}';

                                final waypoints = [
                                  MeetingPoint(
                                    address: l10n.waypointStart,
                                    // Use route coordinates so proximity check
                                    // works with real coordinates (not ocean at 0,0).
                                    latitude: route?.latitude ?? 0.0,
                                    longitude: route?.longitude ?? 0.0,
                                    time: waypointDates.first,
                                    isConfirmed: false,
                                  ),
                                  MeetingPoint(
                                    address: l10n.waypointEnd,
                                    latitude: route?.latitude ?? 0.0,
                                    longitude: route?.longitude ?? 0.0,
                                    time: waypointDates.last,
                                    isConfirmed: false,
                                  ),
                                ];

                                final booking = Booking(
                                  id: bookingId,
                                  userId: userId,
                                  routeId: route?.id ?? '',
                                  routeTitle: routeTitle,
                                  guideId: _selectedGuideId,
                                  guideName: selectedGuide?.fullName,
                                  driverId: _selectedDriverId,
                                  driverName: selectedDriver != null
                                      ? '${selectedDriver.fullName} — ${selectedDriver.vehicleModel}'
                                      : null,
                                  // partnerId = guideId (null when no guide).
                                  // checkInAtWaypoint uses partnerId != null to know if a guide is expected.
                                  partnerId: _selectedGuideId,
                                  startDate: waypointDates.first,
                                  endDate: waypointDates.last,
                                  waypoints: waypoints,
                                  participants: _people,
                                  // Use the dynamically calculated price so the saved
                                  // value matches what the user saw on the booking screen.
                                  totalPrice: _price.toDouble(),
                                  status: BookingStatus.pending,
                                  insuranceIncluded: _needInsurance,
                                  driverEarning: driverEarning,
                                  guideEarning: guideEarning,
                                );

                                final activeTrip = ActiveTrip(
                                  id: tripId,
                                  userId: userId,
                                  driverId: _selectedDriverId,
                                  guideId: _selectedGuideId,
                                  // partnerId = guideId (null when no guide)
                                  // so checkIn does NOT wait for a guide that isn't there.
                                  partnerId: _selectedGuideId,
                                  bookingId: bookingId,
                                  status: 'scheduled',
                                  createdAt: DateTime.now().toIso8601String(),
                                  routeGeometry: const [],
                                  waypoints: waypoints,
                                  customName: routeTitle,
                                  companions: _invitedCompanions,
                                  participantIds: [
                                    userId,
                                    ..._invitedCompanions.map((c) => c.uid),
                                  ],
                                );

                                await Future.wait([
                                  FirestoreDataRepository.instance.saveBooking(
                                    booking,
                                  ),
                                  FirestoreDataRepository.instance
                                      .createActiveTrip(activeTrip),
                                ]);
                                
                                // ── Диалог подтверждения оплаты ──────────────────────
                                if (!context.mounted) return;
                                final pricingNow = _pricingDetails;
                                final int confirmTotal = (pricingNow['totalPrice'] as double).toInt();
                                final int confirmTransport = (pricingNow['pTransport'] as double).toInt();
                                final int confirmService = (pricingNow['pService'] as double).toInt();
                                final int confirmEco = (pricingNow['ecoTax'] as double).toInt();
                                final int confirmInsurance = (pricingNow['insuranceCost'] as double).toInt();
                                String formatMoney(int v) => v.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

                                final bool? confirmed = await showModalBottomSheet<bool>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(ctx).scaffoldBackgroundColor,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40, height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Иконка и заголовок
                                        Container(
                                          width: 64, height: 64,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF34C759), Color(0xFF30D158)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(color: const Color(0xFF34C759).withValues(alpha: 0.3),
                                                blurRadius: 16, offset: const Offset(0, 6)),
                                            ],
                                          ),
                                          child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 30),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Подтверждение оплаты',
                                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('Маршрут: $routeTitle',
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        // Детали расчёта
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              if (confirmTransport > 0) ...[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('🚗 Транспорт', style: TextStyle(fontSize: 14)),
                                                    Text('${formatMoney(confirmTransport)} ₸',
                                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              if (confirmService > 0) ...[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('🧑‍🏫 Гид', style: TextStyle(fontSize: 14)),
                                                    Text('${formatMoney(confirmService)} ₸',
                                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              if (confirmEco > 0) ...[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('🌿 Экосбор', style: TextStyle(fontSize: 14)),
                                                    Text('${formatMoney(confirmEco)} ₸',
                                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              if (confirmInsurance > 0) ...[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('🛡️ Страховка', style: TextStyle(fontSize: 14)),
                                                    Text('${formatMoney(confirmInsurance)} ₸',
                                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              Divider(height: 1, color: Colors.grey.shade300),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('Итого к оплате',
                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  Text('${formatMoney(confirmTotal)} ₸',
                                                    style: const TextStyle(fontSize: 22,
                                                      fontWeight: FontWeight.bold, color: Color(0xFF34C759))),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Тестовый режим badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.science_outlined, size: 14, color: Colors.amber),
                                              SizedBox(width: 6),
                                              Text('Тестовый режим оплаты (Freedom Pay)',
                                                style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Кнопки
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton.icon(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            icon: const Icon(Icons.lock_rounded, size: 18),
                                            label: const Text('Оплатить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF34C759),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Отмена', style: TextStyle(fontSize: 15, color: Colors.grey)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (confirmed != true) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Оплата отменена. Бронь сохранена.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  // Navigate even without payment so user sees their trip
                                  context.go('/active_trips');
                                  return;
                                }

                                // ── Вызов Freedom Pay ────────────────────────
                                if (!context.mounted) return;
                                final paymentService = PaymentService();
                                final bool isSuccess = await paymentService.startPaymentFlow(
                                  context: context,
                                  amount: confirmTotal.toDouble(),
                                  description: 'Оплата маршрута: $routeTitle',
                                  routeId: route?.id ?? '',
                                  userId: userId,
                                );

                                if (!isSuccess) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Оплата отменена или не удалась. Бронь сохранена, но не оплачена.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                              }

                              if (!context.mounted) return;
                              context.go('/active_trips');
                            } catch (e) {
                              String errorMsg = e.toString();
                              if (errorMsg.startsWith('Exception: ')) {
                                errorMsg = errorMsg.substring(11);
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          },
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.bookAction),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }

  // Bug 2: Functional date picker
  Future<void> _pickDate(int index) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDates[index].isBefore(now)
          ? now
          : _selectedDates[index],
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('ru'),
    );
    if (picked == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (!mounted) return;
    
    final oldDt = DateTime(
      _selectedDates[index].year,
      _selectedDates[index].month,
      _selectedDates[index].day,
      _selectedTimes[index].hour,
      _selectedTimes[index].minute,
    );

    final newDt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      pickedTime?.hour ?? _selectedTimes[index].hour,
      pickedTime?.minute ?? _selectedTimes[index].minute,
    );
    
    final diff = newDt.difference(oldDt);

    setState(() {
      for (int i = index; i < _pointCount; i++) {
        final dt = DateTime(
          _selectedDates[i].year,
          _selectedDates[i].month,
          _selectedDates[i].day,
          _selectedTimes[i].hour,
          _selectedTimes[i].minute,
        ).add(diff);
        _selectedDates[i] = dt;
        _selectedTimes[i] = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    });
  }

  Widget _buildInsuranceSelector(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(l10n.insuranceTitle),
        subtitle: Text(
          l10n.insuranceDesc,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        value: _needInsurance,
        activeColor: AppColors.accent,
        checkColor: context.colorScheme.onPrimary,
        onChanged: (bool? val) {
          setState(() => _needInsurance = val ?? false);
        },
      ),
    );
  }

  Widget _buildReceipt(AppLocalizations l10n) {
    final details = _pricingDetails;
    final int pTransport = (details['pTransport'] as double).toInt();
    final int pService = (details['pService'] as double).toInt();
    final int ecoTax = (details['ecoTax'] as double).toInt();
    final int insurance = (details['insuranceCost'] as double).toInt();
    final int total = _price;
    final int days = details['days'] as int;

    final String vType = _selectedVehicleRole == ServiceRole.suvDriver
        ? l10n.vehicleSuv
        : _selectedVehicleRole == ServiceRole.busDriver
        ? l10n.vehicleBus
        : _selectedVehicleRole == ServiceRole.minibusDriver
        ? l10n.vehicleMinibus
        : _selectedVehicleRole == ServiceRole.minivanDriver
        ? l10n.vehicleMinivan
        : l10n.vehicleDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.calculationDetailsTitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 12),

        if (_selectedDriverId != null)
          _buildReceiptRow(l10n.receiptVehicle(vType, days), pTransport),

        if (_selectedGuideId != null)
          _buildReceiptRow(l10n.receiptGuide(days), pService),

        _buildReceiptRow(l10n.receiptEcoTax(_people), ecoTax),

        if (_needInsurance)
          _buildReceiptRow(l10n.receiptInsurance(_people), insurance),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.border),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.receiptTotal,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} ₸',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
        Text(
          l10n.priceIncludesServiceFee,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String title, int amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
          Text(
            '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} ₸',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadTypeSelectors(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedRoadType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              icon: Icon(LucideIcons.map, color: AppColors.textSecondary),
            ),
            items: ['Асфальт', 'Гравий/Грунт', 'Жесткий Offroad'].map((
              String choice,
            ) {
              final isOffroad = choice == 'Жесткий Offroad';
              final isSuv = _selectedVehicleRole == ServiceRole.suvDriver;
              String localizedChoice = choice;
              if (choice == 'Асфальт') localizedChoice = l10n.roadTypeAsphalt;
              if (choice == 'Гравий/Грунт') {
                localizedChoice = l10n.roadTypeGravel;
              }
              if (choice == 'Жесткий Offroad') {
                localizedChoice = l10n.roadTypeOffroad;
              }

              return DropdownMenuItem<String>(
                value: choice,
                enabled: !isOffroad || isSuv,
                child: Text(
                  localizedChoice,
                  style: TextStyle(
                    color: (!isOffroad || isSuv)
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? val) {
              if (val != null) {
                setState(() => _selectedRoadType = val);
              }
            },
          ),
          Divider(height: 1, color: AppColors.border),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.nightTripLabel),
            subtitle: Text(
              l10n.nightTripDesc,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: _isNightTrip,
            activeColor: AppColors.accent,
            checkColor: context.colorScheme.onSecondary,
            onChanged: (bool? val) {
              setState(() => _isNightTrip = val ?? false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteNameInput(AppLocalizations l10n) {
    return TextField(
      controller: _routeNameController,
      decoration: InputDecoration(
        hintText: l10n.hintRouteNameExample,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
      style: const TextStyle(fontSize: 15),
      maxLength: 30,
    );
  }

  Widget _buildDateSelector(int index, AppLocalizations l10n) {
    String placeLabel = '';
    if (widget.controller != null &&
        widget.controller!.waypoints.length > index) {
      placeLabel = widget.controller!.waypoints[index].name;
    }
    if (placeLabel.isEmpty) {
      if (index == 0) {
        placeLabel = l10n.waypointStart;
      } else {
        placeLabel = l10n.waypointStop(index);
      }
    }

    final date = _selectedDates[index];
    final time = _selectedTimes[index];
    final dayStr = '${date.day} ${_getMonthName(date.month, l10n)}';
    final weekdayStr =
        '${_getWeekdayName(date.weekday, l10n)}, '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => _pickDate(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.calendar,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$placeLabel • $dayStr',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    weekdayStr,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _pickDate(index),
              child: Text(
                l10n.actionChange,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Display-only "Финиш" tile shown after the last date row.
  /// Shows estimated return-to-start time based on haversine distance.
  Widget _buildFinishRow(AppLocalizations l10n) {
    if (_selectedDates.isEmpty) return const SizedBox.shrink();

    // --- Calculate estimated return-to-start time ---
    DateTime returnDateTime;
    final waypoints = widget.controller?.waypoints ?? [];
    if (waypoints.length >= 2) {
      final firstWp = waypoints.first;
      final lastWp  = waypoints.last;
      // straight-line distance from last waypoint back to start (km)
      final returnDistKm = RouteCalculator.calculateDistance(
        lastWp.latitude,  lastWp.longitude,
        firstWp.latitude, firstWp.longitude,
      );
      // assume avg return speed 60 km/h → minutes
      final returnMinutes = (returnDistKm / 60.0 * 60).round();
      final lastDateTime = DateTime(
        _selectedDates.last.year,
        _selectedDates.last.month,
        _selectedDates.last.day,
        _selectedTimes.last.hour,
        _selectedTimes.last.minute,
      );
      returnDateTime = lastDateTime.add(Duration(minutes: returnMinutes));
    } else {
      // fallback – no waypoints yet, just show last selected time
      returnDateTime = DateTime(
        _selectedDates.last.year,
        _selectedDates.last.month,
        _selectedDates.last.day,
        _selectedTimes.last.hour,
        _selectedTimes.last.minute,
      );
    }

    final dayStr     = '${returnDateTime.day} ${_getMonthName(returnDateTime.month, l10n)}';
    final timeStr    = '${returnDateTime.hour.toString().padLeft(2, '0')}:${returnDateTime.minute.toString().padLeft(2, '0')}';
    final weekdayStr = '${_getWeekdayName(returnDateTime.weekday, l10n)}, $timeStr';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A84FF).withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0A84FF).withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.flag,
              size: 20,
              color: Color(0xFF0A84FF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏁 Финиш • $dayStr',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$weekdayStr • Возврат к точке старта',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.lock, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPeopleCounter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCounterButton(
            icon: LucideIcons.minus,
            color: AppColors.background,
            onTap: () {
              if (_people > 1) setState(() => _people--);
            },
          ),
          Row(
            children: [
              Icon(LucideIcons.users, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '$_people',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          _buildCounterButton(
            icon: LucideIcons.plus,
            color: AppColors.accent,
            onTap: () {
              if (_people < _maxPeople) {
                setState(() => _people++);
              } else {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.maxPeopleLimit(_maxPeople)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color == AppColors.accent
              ? context.colorScheme.onPrimary
              : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildServiceSelection({
    required String label,
    required AppLocalizations l10n,
    required IconData icon,
    required ServiceRole? selectedRole,
    required bool isGuide,
    required ValueChanged<ServiceRole> onSelect,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: () {
        ServiceSelectionBottomSheet.show(
          context,
          isGuide: isGuide,
          initialSelection: selectedRole,
          onSelected: onSelect,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selectedRole != null
                    ? AppColors.accent
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                selectedRole?.icon ?? icon,
                color: selectedRole != null
                    ? context.colorScheme.onPrimary
                    : AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedRole?.title ?? label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    selectedRole?.subtitle ??
                        (isGuide
                            ? l10n.guideServiceDesc
                            : l10n.driverServiceDesc),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedRole != null)
              IconButton(
                icon: Icon(LucideIcons.xCircle, color: AppColors.textSecondary),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Icon(LucideIcons.chevronDown, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSelection(AppLocalizations l10n) {
    if (_isLoadingDrivers) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    final drivers = _filteredDrivers;
    if (drivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          l10n.noDriversAvailable,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: drivers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final isSelected = driver.id == _selectedDriverId;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDriverId = driver.id);
              _checkAndClampPeople(); // Refresh capacity restrictions based on selected driver
            },
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) =>
                                PartnerProfileSheet(profile: driver),
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage:
                              (driver.photoUrl?.isNotEmpty ?? false)
                              ? NetworkImage(driver.photoUrl!)
                              : null,
                          backgroundColor: AppColors.background,
                          child: (driver.photoUrl?.isEmpty ?? true)
                              ? const Icon(LucideIcons.user, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.star,
                        color: AppColors.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        driver.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    driver.ownerName.isNotEmpty
                        ? driver.ownerName
                        : driver.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '🚗 ${driver.vehicleModel.isNotEmpty ? driver.vehicleModel : 'Авто'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  () {
                    // Seats available for tourists (excluding driver + guide)
                    final cap = driver.vehicleCapacity > 0
                        ? driver.vehicleCapacity
                        : 4;
                    final forTourists =
                        cap -
                        1 - // driver
                        (_selectedGuideId != null ? 1 : 0); // guide
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.seatsAvailable(
                            cap,
                            forTourists > 0 ? forTourists : 1,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    );
                  }(),
                  const Spacer(),
                  Text(
                    '${driver.pricePerKm.toInt()} ${l10n.currencyPerKm}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuideSelection(AppLocalizations l10n) {
    if (_isLoadingGuides) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    final guides = _filteredGuides;
    if (guides.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          l10n.noGuidesAvailable,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: guides.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final guide = guides[index];
          final isSelected = guide.id == _selectedGuideId;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedGuideId = guide.id);
              _checkAndClampPeople(); // Update max capacity constraint
            },
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : context.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : Colors
                            .transparent, // Only borders when selected, or very faint
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) =>
                                PartnerProfileSheet(profile: guide),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: (guide.photoUrl?.isNotEmpty ?? false)
                              ? NetworkImage(guide.photoUrl!)
                              : null,
                          backgroundColor: AppColors.background,
                          child: (guide.photoUrl?.isEmpty ?? true)
                              ? const Icon(LucideIcons.user, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.star,
                              color: AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              guide.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    guide.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guide.languages.join('. '),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '${guide.pricePerDay.toInt()} ${l10n.currencyPerDay}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month, AppLocalizations l10n) {
    switch (month) {
      case 1:
        return l10n.month1;
      case 2:
        return l10n.month2;
      case 3:
        return l10n.month3;
      case 4:
        return l10n.month4;
      case 5:
        return l10n.month5;
      case 6:
        return l10n.month6;
      case 7:
        return l10n.month7;
      case 8:
        return l10n.month8;
      case 9:
        return l10n.month9;
      case 10:
        return l10n.month10;
      case 11:
        return l10n.month11;
      case 12:
        return l10n.month12;
      default:
        return '';
    }
  }

  String _getWeekdayName(int weekday, AppLocalizations l10n) {
    switch (weekday) {
      case 1:
        return l10n.weekday1;
      case 2:
        return l10n.weekday2;
      case 3:
        return l10n.weekday3;
      case 4:
        return l10n.weekday4;
      case 5:
        return l10n.weekday5;
      case 6:
        return l10n.weekday6;
      case 7:
        return l10n.weekday7;
      default:
        return '';
    }
  }

  // ─── Companion invite UI ─────────────────────────────────────────────────

  Widget _buildCompanionInviteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Список добавленных компаньонов
        for (final companion in _invitedCompanions) ...[
          _buildCompanionTile(companion),
          const SizedBox(height: 8),
        ],

        // Кнопка добавить
        GestureDetector(
          onTap: _showCompanionSearchSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.userPlus,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '+ Добавить клиента',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '(Необязательно) Вы можете пригласить зарегистрированных пользователей',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanionTile(CompanionInfo companion) {
    final initials = companion.displayName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            backgroundImage: companion.photoUrl != null
                ? NetworkImage(companion.photoUrl!)
                : null,
            child: companion.photoUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companion.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Компаньон',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
            onPressed: () {
              setState(() => _invitedCompanions.remove(companion));
            },
          ),
        ],
      ),
    );
  }

  void _showCompanionSearchSheet() {
    final currentUid = AuthService.instance.currentFirebaseUser?.uid ?? '';
    final searchController = TextEditingController();
    List<User> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            Future<void> doSearch(String q) async {
              if (q.trim().isEmpty) {
                setSheetState(() {
                  searchResults = [];
                  isSearching = false;
                });
                return;
              }
              setSheetState(() => isSearching = true);
              final results = await FirestoreDataRepository.instance
                  .searchUsersByName(q, excludeUid: currentUid);
              setSheetState(() {
                searchResults = results;
                isSearching = false;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Найти клиента',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Введите имя пользователя приложения',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search field
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Имя пользователя...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (v) => doSearch(v),
                  ),
                  const SizedBox(height: 16),

                  // Results
                  if (searchResults.isEmpty &&
                      !isSearching &&
                      searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Пользователь не найден',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final u = searchResults[i];
                          final displayName =
                              u.name ?? u.firstName ?? 'Без имени';
                          final initials = displayName
                              .split(' ')
                              .where((s) => s.isNotEmpty)
                              .take(2)
                              .map((s) => s[0].toUpperCase())
                              .join();
                          final alreadyAdded = _invitedCompanions.any(
                            (c) => c.uid == u.id,
                          );

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.accent
                                      .withValues(alpha: 0.15),
                                  backgroundImage: u.photoUrl != null
                                      ? NetworkImage(u.photoUrl!)
                                      : null,
                                  child: u.photoUrl == null
                                      ? Text(
                                          initials,
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (u.phoneNumber.isNotEmpty)
                                        Text(
                                          u.phoneNumber,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: alreadyAdded
                                      ? null
                                      : () {
                                          setState(() {
                                            _invitedCompanions.add(
                                              CompanionInfo(
                                                uid: u.id,
                                                displayName: displayName,
                                                photoUrl: u.photoUrl,
                                                addedAt: DateTime.now()
                                                    .toIso8601String(),
                                              ),
                                            );
                                          });
                                          Navigator.pop(sheetCtx);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(
                                    alreadyAdded ? 'Добавлен' : 'Добавить',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
