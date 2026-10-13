import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/app_models.dart';
import '../models/tour_models.dart' as app_models;
import '../repository/firestore_data_repository.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../utils/date_formatter.dart';
import '../l10n/app_localizations.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(l10n.myOrdersAndChats),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSegmentedControl(l10n),
          ),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final uid = AuthService.instance.currentFirebaseUser?.uid ?? '';

    return FutureBuilder<List<Booking>>(
      future: FirestoreDataRepository.instance.getUserBookings(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text(l10n.myOrdersLoadError(snapshot.error.toString())));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmpty(l10n);
        }

        final upcoming = bookings
            .where(
              (b) =>
                  b.status == BookingStatus.confirmed ||
                  b.status == BookingStatus.pending ||
                  b.status == BookingStatus.inProgress,
            )
            .toList();

        final past = bookings
            .where(
              (b) =>
                  b.status == BookingStatus.completed ||
                  b.status == BookingStatus.cancelled,
            )
            .toList();

        if (_selectedTabIndex == 2) {
          return _buildSavedChatsTab(bookings, uid, l10n);
        }

        final items = _selectedTabIndex == 0 ? upcoming : past;

        if (items.isEmpty) {
          return _buildEmpty(l10n);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _buildOrderCard(items[i], l10n),
        );
      },
    );
  }

  Widget _buildSavedChatsTab(List<Booking> allBookings, String uid, AppLocalizations l10n) {
    return StreamBuilder<List<String>>(
      stream: FirestoreDataRepository.instance.streamHiddenChats(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        final hiddenChatIds = snapshot.data ?? [];

        // A chat is considered available if the booking is confirmed/inProgress/completed
        // AND its ID is not in the hiddenChatIds array.
        final visibleChats = allBookings.where((b) {
          final isEligible =
              b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.inProgress ||
              b.status == BookingStatus.completed;
          return isEligible && !hiddenChatIds.contains(b.id);
        }).toList();

        if (visibleChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.messageSquare,
                  size: 56,
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.myOrdersNoSavedChats,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myOrdersNoSavedChatsDesc,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visibleChats.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final booking = visibleChats[i];
            return _buildSavedChatCard(booking, uid, l10n);
          },
        );
      },
    );
  }

  Widget _buildSavedChatCard(Booking booking, String uid, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () async {
        // Fetch the active trip associated with this booking (can be completed)
        final trip = await FirestoreDataRepository.instance
            .getActiveTripByBookingId(booking.id);
        if (!mounted) return;

        if (trip != null) {
          context.push('/messenger', extra: {'tripId': trip.id});
        } else {
          // fallback if not found at all
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.myOrdersChatUnavailable),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.messageCircle,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.routeTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatTripDates(
                          booking.startDate,
                          booking.endDate,
                        ),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2, color: context.errorColor),
              onPressed: () => _confirmDeleteChat(uid, booking.id, l10n),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat(String uid, String bookingId, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.myOrdersDeleteChatTitle),
        content: Text(
          l10n.myOrdersDeleteChatDesc,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.myOrdersDeleteChatCancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirestoreDataRepository.instance.hideChat(uid, bookingId);
            },
            child: Text(l10n.myOrdersDeleteChatConfirm, style: TextStyle(color: context.errorColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.packageOpen,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.myOrdersNoOrders,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.myOrdersNoOrdersDesc,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/constructor'),
            child: Text(l10n.myOrdersCreateRoute),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(AppLocalizations l10n) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _selectedTabIndex == 0
                ? Alignment.centerLeft
                : _selectedTabIndex == 1
                ? Alignment.center
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      l10n.myOrdersTabUpcoming,
                      style: TextStyle(
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      l10n.myOrdersTabPast,
                      style: TextStyle(
                        fontWeight: _selectedTabIndex == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 1
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 2),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      l10n.myOrdersTabChats,
                      style: TextStyle(
                        fontWeight: _selectedTabIndex == 2
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 2
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Booking booking, AppLocalizations l10n) {
    final isActive =
        booking.status == BookingStatus.confirmed ||
        booking.status == BookingStatus.inProgress ||
        booking.status == BookingStatus.pending;
    final isCompleted = booking.status == BookingStatus.completed;

    final statusLabel = switch (booking.status) {
      BookingStatus.pending => l10n.bookingStatusPending,
      BookingStatus.confirmed => l10n.bookingStatusConfirmed,
      BookingStatus.inProgress => l10n.bookingStatusInProgress,
      BookingStatus.completed => l10n.bookingStatusCompleted,
      BookingStatus.cancelled => l10n.bookingStatusCancelled,
    };

    final priceStr =
        '${booking.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';

    return FutureBuilder<app_models.Route?>(
      future: FirestoreDataRepository.instance.getRouteById(booking.routeId),
      builder: (context, snapshot) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.image,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  booking.routeTitle,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                priceStr,
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormatter.formatTripDates(
                                  booking.startDate,
                                  booking.endDate,
                                ),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.textSecondary
                                                .withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (isActive)
                                GestureDetector(
                                  onTap: () => _showBookingDetails(booking, l10n),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      LucideIcons.arrowRight,
                                      size: 16,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted) ...[
                Divider(height: 1, color: AppColors.border),
                InkWell(
                  onTap: () => context.push('/constructor'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.rotateCcw,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.myOrdersRepeatRoute,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showBookingDetails(Booking booking, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.mapPin,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.routeTitle,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                _statusChip(booking.status, l10n),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // Details list
                      _detailRow(
                        LucideIcons.calendar,
                        l10n.myOrdersDetailStartDate,
                        DateFormatter.formatTripDates(
                          booking.startDate,
                          booking.endDate,
                        ),
                      ),
                      _detailRow(
                        LucideIcons.users,
                        l10n.myOrdersDetailParticipants,
                        l10n.myOrdersDetailParticipantsCount(booking.participants),
                      ),
                      _detailRow(LucideIcons.walletCards, l10n.myOrdersDetailPrice, () {
                        final p = booking.totalPrice.toInt();
                        final formatted = p.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (m) => '${m[1]} ',
                        );
                        return '$formatted ₸';
                      }()),
                      if (booking.guideId != null)
                        _detailRow(LucideIcons.user, l10n.myOrdersDetailGuide, l10n.myOrdersDetailAssigned),
                      if (booking.driverId != null)
                        _detailRow(LucideIcons.car, l10n.myOrdersDetailDriver, l10n.myOrdersDetailAssigned),

                      const SizedBox(height: 24),
                      Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // Open active trip screen button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(LucideIcons.navigation, size: 18),
                          label: Text(
                            l10n.myOrdersOpenRoute,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: context.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.push('/active_trips');
                          },
                        ),
                      ),
                      if (booking.status == BookingStatus.pending) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            icon: const Icon(LucideIcons.xCircle, size: 18),
                            label: Text(
                              AppLocalizations.of(context)!.bookingStatusCancelled, // Or a specific 'Cancel' string
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.errorColor,
                              side: BorderSide(color: context.errorColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await FirestoreDataRepository.instance
                                  .updateBookingStatus(
                                      booking.id, BookingStatus.cancelled);
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ],
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

  Widget _statusChip(BookingStatus status, AppLocalizations l10n) {
    final label = switch (status) {
      BookingStatus.pending => l10n.bookingStatusPending,
      BookingStatus.confirmed => l10n.bookingStatusConfirmed,
      BookingStatus.inProgress => l10n.bookingStatusInProgress,
      BookingStatus.completed => l10n.bookingStatusCompleted,
      BookingStatus.cancelled => l10n.bookingStatusCancelled,
    };
    final color =
        (status == BookingStatus.inProgress ||
            status == BookingStatus.confirmed)
        ? AppColors.success
        : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

