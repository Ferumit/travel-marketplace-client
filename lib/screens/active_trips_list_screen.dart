import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../models/booking_models.dart';
import '../models/user_models.dart';
import '../repository/firestore_data_repository.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';

class ActiveTripsListScreen extends StatefulWidget {
  const ActiveTripsListScreen({super.key});

  @override
  State<ActiveTripsListScreen> createState() => _ActiveTripsListScreenState();
}

class _ActiveTripsListScreenState extends State<ActiveTripsListScreen> {
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final status = await LocationService.instance.requestPermission();
    if (status != LocationStatus.ready) {
      debugPrint('[ActiveTripsListScreen] Нет прав на геолокацию');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId =
        AuthService.instance.currentFirebaseUser?.uid ??
        AuthService.instance.appUser?.id;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
            onPressed: () => context.go('/'),
          ),
          title: Text(
            l10n.activeTripsTitle,
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Text(
            l10n.authRequired,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          l10n.activeTripsTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface.withValues(alpha: 0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Map
          Positioned.fill(
            child: YandexMap(
              mode2DEnabled: true,
              logoAlignment: const MapAlignment(
                horizontal: HorizontalAlignment.left,
                vertical: VerticalAlignment.bottom,
              ),
              onMapCreated: (controller) async {
                await controller.toggleUserLayer(visible: true);
                final loc = await LocationService.instance.getCurrentPosition();
                if (loc != null) {
                  await controller.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: Point(
                          latitude: loc.latitude,
                          longitude: loc.longitude,
                        ),
                        zoom: 13.0,
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Gradient Overlay to ensure text visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: StreamBuilder<List<ActiveTrip>>(
              stream: FirestoreDataRepository.instance.streamActiveTrips(
                userId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l10n.errorMessage(snapshot.error.toString()),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }

                final trips = snapshot.data ?? [];

                if (trips.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noActiveTrips,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(context, trip, l10n);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, ActiveTrip trip, AppLocalizations l10n) {
    final isWaiting = trip.status == 'waiting';
    final currentUid = AuthService.instance.currentFirebaseUser?.uid ?? '';
    final isOwner = trip.userId == currentUid;

    return GestureDetector(
      onTap: () => context.push('/active/${trip.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.mapPin,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          trip.customName ??
                              l10n.routeNumLabel(trip.id.substring(trip.id.length - 4)),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Компаньон',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isWaiting ? LucideIcons.clock : LucideIcons.play,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isWaiting ? l10n.statusWaitingDriver : l10n.statusOnWay,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.moreVertical,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) async {
                if (value == 'rename') {
                  _showRenameDialog(trip, l10n);
                } else if (value == 'info') {
                  context.push('/active/${trip.id}');
                } else if (value == 'invite') {
                  _showAddCompanionSheet(trip, l10n);
                } else if (value == 'cancel') {
                  _cancelTrip(trip, l10n);
                }
              },
              itemBuilder: (context) => [
                if (isOwner)
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.edit2, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.actionRename, style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.actionMoreInfo, style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuItem(
                    value: 'invite',
                    child: Row(
                      children: [
                        Icon(LucideIcons.userPlus, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Пригласить клиента', style: TextStyle(color: AppColors.accent)),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.xCircle,
                        size: 18,
                        color: context.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.actionCancelRoute,
                        style: TextStyle(color: context.errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(ActiveTrip trip, AppLocalizations l10n) async {
    final ctrl = TextEditingController(text: trip.customName);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.actionRename, style: TextStyle(color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: l10n.hintRenameRoute,
              border: const OutlineInputBorder(),
            ),
            maxLength: 30,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return l10n.errorEnterName;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (newName != null && mounted) {
      await FirestoreDataRepository.instance.updateTripName(trip.id, newName);
    }

    // Задерживаем очистку контроллера, пока диалог не завершит анимацию закрытия (во избежание креша во фреймворке)
    Future.delayed(const Duration(milliseconds: 300), () => ctrl.dispose());
  }

  Future<void> _cancelTrip(ActiveTrip trip, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.dialogCancelRouteTitle, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.dialogCancelRouteDesc,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionDoNotCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.actionYesCancel),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirestoreDataRepository.instance.completeTripBatch(
          tripId: trip.id,
          tripStatus: 'cancelled',
          bookingId: trip.bookingId,
          bookingStatus: BookingStatus.cancelled,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.msgRouteCancelled)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorCancelRoute(e.toString())),
              backgroundColor: context.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showAddCompanionSheet(ActiveTrip trip, AppLocalizations l10n) {
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
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          Future<void> doSearch(String q) async {
            if (q.trim().isEmpty) {
              setSheetState(() { searchResults = []; isSearching = false; });
              return;
            }
            setSheetState(() => isSearching = true);
            final results = await FirestoreDataRepository.instance
                .searchUsersByName(q, excludeUid: currentUid);
            setSheetState(() { searchResults = results; isSearching = false; });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 20),
                Text('Пригласить клиента',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Введите имя пользователя',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),

                TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Имя пользователя...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: isSearching
                        ? const Padding(padding: EdgeInsets.all(12),
                            child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border)),
                  ),
                  onChanged: (v) => doSearch(v),
                ),
                const SizedBox(height: 16),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final u = searchResults[i];
                      final displayName = u.name ?? u.firstName ?? 'Без имени';
                      final initials = displayName.split(' ')
                          .where((s) => s.isNotEmpty).take(2)
                          .map((s) => s[0].toUpperCase()).join();
                      final alreadyIn = trip.companions.any((c) => c.uid == u.id);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                              backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                              child: u.photoUrl == null
                                  ? Text(initials, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(u.phoneNumber, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            )),
                            ElevatedButton(
                              onPressed: alreadyIn ? null : () async {
                                final companion = CompanionInfo(
                                  uid: u.id,
                                  displayName: displayName,
                                  photoUrl: u.photoUrl,
                                  addedAt: DateTime.now().toIso8601String(),
                                );
                                await FirestoreDataRepository.instance
                                    .addCompanionToTrip(trip.id, companion);
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$displayName добавлен в маршрут')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero),
                              child: Text(alreadyIn ? 'Добавлен' : 'Добавить',
                                style: const TextStyle(fontSize: 13)),
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
      ),
    ).whenComplete(() => searchController.dispose());
  }
}
