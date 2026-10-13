import '../theme/app_colors.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../repository/firestore_data_repository.dart';
import '../services/mesh_service.dart';
import '../services/connectivity_service.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  bool _isHolding = false;
  bool _isSent = false;
  bool _pointerDown = false;

  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _activeTripId;
  Position? _position;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ровно 2 секунды удержания
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isSent = true);
        MeshService.instance.activateBeacon(tripId: _activeTripId);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() {});
        });
      }
    });

    _startGps();
    _loadActiveTrip();
  }

  Future<void> _startGps() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) {
        if (mounted) setState(() => _position = pos);
      },
      onError: (_) {},
      cancelOnError: false,
    );

    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).then((pos) {
      if (mounted) setState(() => _position = pos);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    MeshService.instance.deactivateBeacon();
    super.dispose();
  }

  Future<void> _loadActiveTrip() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final trip = await FirestoreDataRepository.instance.getActiveTripForUser(uid);
      if (mounted && trip != null) {
        setState(() => _activeTripId = trip.id);
      }
    } catch (_) {}
  }

  void _startHolding() {
    if (_isSent || _pointerDown) return;
    _pointerDown = true;
    setState(() => _isHolding = true);
    // Для точных 3 секунд зажатия обнуляем и запускаем 
    _progressController.forward(from: 0.0);
  }

  void _stopHolding() {
    if (_isSent) return;
    _pointerDown = false;
    // При отпускании моментально сбрасываем, чтобы избежать накопления времени
    _progressController.stop();
    _progressController.value = 0.0;
    setState(() => _isHolding = false);
  }

  String _formatCoords() {
    if (_position == null) return 'Определение координат...';
    final lat = _position!.latitude;
    final lng = _position!.longitude;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir, ${lng.abs().toStringAsFixed(4)}° $lngDir';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0C1017), // Улучшенный темный фон
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Header (с блюром и красивой типографикой)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, -3 * (1 - _pulseAnimation.value.clamp(1.0, 1.2))),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: context.errorColor.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: context.errorColor.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(LucideIcons.bellRing, color: context.errorColor, size: 20),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.sosEmergencyMode.toUpperCase(),
                                      style: TextStyle(
                                        color: context.errorColor,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.0,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(LucideIcons.x, color: Colors.white70, size: 22),
                                    onPressed: () => context.pop(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Center(
                              child: _isSent ? _buildSentState(l10n) : _buildSOSInteractiveArea(l10n),
                            ),
                          ),

                          if (!_isSent) ...[
                            // Toggles section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                children: [
                                  _buildToggleItem(l10n.sosGuideToggle, true),
                                  const SizedBox(height: 12),
                                  _buildToggleItem(l10n.sosDriverToggle, true),
                                  const SizedBox(height: 12),
                                  _buildToggleItem(l10n.sosRescueServiceToggle, true, isAlert: true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Footer GPS
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: _buildCoordinatesCard(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSInteractiveArea(AppLocalizations l10n) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Правильный "ареал" анимации, который строго привязан к центру кнопки
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 260 * _pulseAnimation.value,
              height: 260 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.errorColor.withValues(alpha: 0.2),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                  BoxShadow(
                    color: context.errorColor.withValues(alpha: 0.1),
                    blurRadius: 150,
                    spreadRadius: 60 * _pulseAnimation.value,
                  )
                ],
              ),
            );
          },
        ),
        // Сама кнопка
        _buildSOSButton(l10n),
      ],
    );
  }

  Widget _buildSOSButton(AppLocalizations l10n) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _startHolding(),
      onPointerUp: (_) => _stopHolding(),
      onPointerCancel: (_) => _stopHolding(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Поглощаем все сдвиги (свайпы), чтобы SingleChildScrollView не "сбросил" нажатие
        onVerticalDragUpdate: (_) {},
        onHorizontalDragUpdate: (_) {},
        child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Подложка для кольца прогресса
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                color: context.errorColor.withValues(alpha: 0.15),
              ),
            ),
            // Анимированное кольцо прогресса (теперь ровно 3 секунды)
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) => SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: _progressController.value,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(context.errorColor),
                ),
              ),
            ),
            // Центральная кнопка
            AnimatedScale(
              scale: _isHolding ? 0.90 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6666),
                      context.errorColor,
                      const Color(0xFFC00000),
                    ],
                  ),
                  boxShadow: [
                    if (!_isHolding)
                      BoxShadow(
                        color: context.errorColor.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      )
                    else
                       BoxShadow(
                        color: context.errorColor.withValues(alpha: 0.8),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 15,
                      spreadRadius: -5,
                      offset: const Offset(-5, -5),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: -5,
                      offset: const Offset(5, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.radioTower,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.sosButtonText, // "SOS"
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ЗАЖАТЬ НА 3 СЕК.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    final coordStr = _formatCoords();
    final hasGps = _position != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasGps
                  ? context.errorColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              hasGps
                  ? Icon(LucideIcons.mapPin, color: context.errorColor, size: 20)
                  : const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
              const SizedBox(width: 12),
              Column(
                 mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ВЕРНЫЕ КООРДИНАТЫ',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coordStr,
                    style: TextStyle(
                      color: hasGps ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: hasGps ? 15 : 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentState(AppLocalizations l10n) {
    final meshActive = MeshService.instance.isStarted && MeshService.instance.isBluetoothActive;
    final isOnline = ConnectivityService.instance.isOnline;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value.clamp(0.9, 1.1),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withValues(alpha: 0.8),
                      AppColors.success,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.4),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.check, color: Colors.white, size: 60),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          l10n.sosSignalSent,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 24),
        if (_position != null)
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: context.errorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.errorColor.withValues(alpha: 0.3)),
            ),
             child: Text(
              _formatCoords(),
               style: TextStyle(
                color: context.errorColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isOnline ? const Color(0xFF34C759) : Colors.orange).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isOnline ? const Color(0xFF34C759) : Colors.orange).withValues(alpha: 0.3),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              isOnline ? LucideIcons.cloud : LucideIcons.cloudOff,
              size: 16,
              color: isOnline ? const Color(0xFF34C759) : Colors.orange,
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? 'CLOUD: Сигнал доставлен' : 'ОФФЛАЙН: Отправим при сети',
              style: TextStyle(
                color: isOnline ? const Color(0xFF34C759) : Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (meshActive ? const Color(0xFF00E5FF) : Colors.grey).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (meshActive ? const Color(0xFF00E5FF) : Colors.grey).withValues(alpha: 0.3),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              LucideIcons.radio,
              size: 16,
              color: meshActive ? const Color(0xFF00E5FF) : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              meshActive ? 'MESH: Активная трансляция' : 'MESH: Недоступен',
              style: TextStyle(
                color: meshActive ? const Color(0xFF00E5FF) : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
        if (_activeTripId != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.navigation, size: 16, color: AppColors.accent),
                const SizedBox(width: 10),
                Text(
                  'РАЦИЯ: Участники оповещены',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleItem(String label, bool defaultChecked, {bool isAlert = false}) {
    return _SOSToggle(
      label: label,
      initialValue: defaultChecked,
      isAlert: isAlert,
    );
  }
}

class _SOSToggle extends StatefulWidget {
  final String label;
  final bool initialValue;
  final bool isAlert;

  const _SOSToggle({
    required this.label,
    required this.initialValue,
    this.isAlert = false,
  });

  @override
  State<_SOSToggle> createState() => _SOSToggleState();
}

class _SOSToggleState extends State<_SOSToggle> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isAlert
                 ? context.errorColor.withValues(alpha: 0.08)
                 : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
               color: widget.isAlert
                   ? context.errorColor.withValues(alpha: 0.3)
                   : Colors.white.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isAlert ? context.errorColor : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isOn = !_isOn),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 54,
                  height: 30,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _isOn
                        ? (widget.isAlert ? context.errorColor : AppColors.success)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _isOn ? Colors.transparent : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: _isOn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isOn)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
