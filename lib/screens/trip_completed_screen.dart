import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/booking_models.dart';
import '../models/user_models.dart';
import '../repository/firestore_data_repository.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../utils/date_formatter.dart';
import '../l10n/app_localizations.dart';
import '../widgets/review_sheet.dart';

class TripCompletedScreen extends StatefulWidget {
  final String tripId;
  const TripCompletedScreen({super.key, required this.tripId});

  @override
  State<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen> {
  // trip data: loaded to extract bookingId
  Booking? _booking;

  bool _routeFaved = false;
  bool _guideFaved = false;
  bool _driverFaved = false;
  bool _isTogglingRoute = false;
  bool _isTogglingGuide = false;
  bool _isTogglingDriver = false;
  bool _isSharingRoute = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    final futures = await Future.wait([
      FirestoreDataRepository.instance
          .streamSpecificActiveTrip(widget.tripId)
          .first,
      if (uid != null) FirestoreDataRepository.instance.getUser(uid),
    ]);

    final trip = futures[0] as ActiveTrip?;
    final user = futures.length > 1 ? futures[1] as User? : null;

    Booking? booking;
    if (trip != null) {
      booking = await FirestoreDataRepository.instance.getBookingById(
        trip.bookingId,
      );
    }

    if (mounted) {
      setState(() {
        _booking = booking;
        if (booking != null && user != null) {
          _routeFaved = user.favoriteRouteIds.contains(booking.routeId);
          _guideFaved =
              booking.guideId != null &&
              user.favoriteGuideIds.contains(booking.guideId);
          _driverFaved =
              booking.driverId != null &&
              user.favoriteDriverIds.contains(booking.driverId);
        }
      });
    }
  }

  Future<void> _toggleRoute() async {
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null || _booking == null || _isTogglingRoute) return;
    setState(() => _isTogglingRoute = true);
    await FirestoreDataRepository.instance.toggleFavoriteRoute(
      uid,
      _booking!.routeId,
    );
    setState(() {
      _routeFaved = !_routeFaved;
      _isTogglingRoute = false;
    });
  }

  Future<void> _toggleGuide() async {
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null || _booking?.guideId == null || _isTogglingGuide) return;
    setState(() => _isTogglingGuide = true);
    await FirestoreDataRepository.instance.toggleFavoriteGuide(
      uid,
      _booking!.guideId!,
    );
    setState(() {
      _guideFaved = !_guideFaved;
      _isTogglingGuide = false;
    });
  }

  Future<void> _toggleDriver() async {
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null || _booking?.driverId == null || _isTogglingDriver) return;
    setState(() => _isTogglingDriver = true);
    await FirestoreDataRepository.instance.toggleFavoriteDriver(
      uid,
      _booking!.driverId!,
    );
    setState(() {
      _driverFaved = !_driverFaved;
      _isTogglingDriver = false;
    });
  }

  Future<void> _shareRoute() async {
    if (_booking == null || _isSharingRoute) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSharingRoute = true);
    await FirestoreDataRepository.instance.shareRoute(_booking!.routeId);
    setState(() => _isSharingRoute = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tripCompletedShareSuccess),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Success header
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/mountains_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: AppColors.surface.withValues(alpha: 0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tripCompletedTitle,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tripCompletedSubtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: const BorderRadius.all(Radius.circular(2)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Route info (real data)
                      if (_booking != null) ...[
                          Text(
                            _booking!.routeTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        const SizedBox(height: 4),
                          Text(
                            DateFormatter.formatTripDates(
                              _booking!.startDate,
                              _booking!.endDate,
                            ),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],

                      Text(
                        l10n.tripCompletedStatsTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildStatCard(
                            icon: LucideIcons.mapPin,
                            iconColor: Colors.amber,
                            value: '42.3 км',
                            label: l10n.tripCompletedStatDistance,
                            context: context,
                          ),
                          _buildStatCard(
                            icon: LucideIcons.clock,
                            iconColor: AppColors.accent,
                            value: '3 ч 24 мин',
                            label: l10n.tripCompletedStatTime,
                            context: context,
                          ),
                          _buildStatCard(
                            icon: LucideIcons.mountain,
                            iconColor: Colors.green,
                            value: '1,840 м',
                            label: l10n.tripCompletedStatMaxHeight,
                            context: context,
                          ),
                          _buildStatCard(
                            icon: LucideIcons.trendingUp,
                            iconColor: Colors.purple,
                            value: '12.4 км/ч',
                            label: l10n.tripCompletedStatAvgSpeed,
                            context: context,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Bug 6: Favorites section
                      Text(
                        l10n.tripCompletedAddToFavorites,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildFavButton(
                            label: l10n.tripCompletedFavRoute,
                            icon: LucideIcons.map,
                            isFaved: _routeFaved,
                            isLoading: _isTogglingRoute,
                            onTap: _toggleRoute,
                            context: context,
                          ),
                          const SizedBox(width: 10),
                          if (_booking?.guideId != null)
                            _buildFavButton(
                              label: l10n.tripCompletedFavGuide,
                              icon: LucideIcons.user,
                              isFaved: _guideFaved,
                              isLoading: _isTogglingGuide,
                              onTap: _toggleGuide,
                              context: context,
                            ),
                          if (_booking?.guideId != null)
                            const SizedBox(width: 10),
                          if (_booking?.driverId != null)
                            _buildFavButton(
                              label: l10n.tripCompletedFavDriver,
                              icon: LucideIcons.car,
                              isFaved: _driverFaved,
                              isLoading: _isTogglingDriver,
                              onTap: _toggleDriver,
                              context: context,
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Оставить отзыв ───────────────────────────────
                      if (_booking != null) ...[
                        Text(
                          'Оставить отзыв',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_booking!.guideId != null)
                          _buildReviewButton(
                            label: 'Оценить гида',
                            icon: LucideIcons.flag,
                            color: Colors.green,
                            onTap: () => showReviewSheet(
                              context: context,
                              bookingId: _booking!.id,
                              targetId: _booking!.guideId!,
                              targetName: _booking!.guideName ?? 'Гид',
                              targetRole: 'guide',
                            ),
                            context: context,
                          ),
                        if (_booking!.guideId != null) const SizedBox(height: 10),
                        if (_booking!.driverId != null)
                          _buildReviewButton(
                            label: 'Оценить водителя',
                            icon: LucideIcons.car,
                            color: const Color(0xFF007AFF),
                            onTap: () => showReviewSheet(
                              context: context,
                              bookingId: _booking!.id,
                              targetId: _booking!.driverId!,
                              targetName: _booking!.driverName ?? 'Водитель',
                              targetRole: 'driver',
                            ),
                            context: context,
                          ),
                        const SizedBox(height: 24),
                      ],

                      // Actions
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.accent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isSharingRoute ? null : _shareRoute,
                          child: _isSharingRoute
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.share2),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.tripCompletedShareAction,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => context.go('/my-orders'),
                          child: Text(
                            l10n.tripCompletedViewOrdersAction,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => context.go('/'),
                          child: Text(
                            l10n.tripCompletedHomeAction,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavButton({
    required String label,
    required IconData icon,
    required bool isFaved,
    required bool isLoading,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isFaved
                ? context.theme.colorScheme.error.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFaved ? context.theme.colorScheme.error : AppColors.border,
            ),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      Icon(
                        isFaved ? LucideIcons.heart : icon,
                        size: 22,
                        color: isFaved
                            ? context.theme.colorScheme.error
                            : AppColors.textSecondary,
                      ),
                    const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFaved
                              ? context.theme.colorScheme.error
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildReviewButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
      ),
    );
  }


  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

