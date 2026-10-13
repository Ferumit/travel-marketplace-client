import '../theme/app_colors.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/chat_message.dart';
import '../repository/chat_repository.dart';
import '../services/auth_service.dart';
import '../repository/firestore_data_repository.dart';
import '../widgets/partner_profile_sheet.dart';
import '../l10n/app_localizations.dart';

class MessengerScreen extends StatefulWidget {
  final String tripId;
  final String title;

  const MessengerScreen({super.key, required this.tripId, required this.title});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String get _currentUserId =>
      AuthService.instance.currentFirebaseUser?.uid ?? 'unknown';

  late StreamSubscription<List<ConnectivityResult>> _connSub;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkConnectivity() async {
    await Connectivity().checkConnectivity();
  }

  @override
  void dispose() {
    _connSub.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      // Send normally via Firestore
      await ChatRepository.instance.sendMessage(
        tripId: widget.tripId,
        text: text,
        senderId: _currentUserId,
        isPartner: false,
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.messengerSendError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Guard: chat is meaningless without a valid trip
    if (widget.tripId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 56,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.messengerNoActiveRoute,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.messengerNoActiveRouteDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatRepository.instance.streamMessages(widget.tripId),
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
                      l10n.messengerLoadError,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.messengerNoMessages,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe =
                        message.senderId == _currentUserId &&
                        !message.isPartner;

                    final showDate =
                        index == messages.length - 1 ||
                        !_isSameDay(
                          messages[index].timestamp,
                          messages[index + 1].timestamp,
                        );

                    return Column(
                      children: [
                        if (showDate) _buildDateLabel(message.timestamp),
                        _buildMessageBubble(
                          text: message.text,
                          isMe: isMe,
                          time: DateFormat('HH:mm').format(message.timestamp),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showParticipantsDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      final activeTrip = await FirestoreDataRepository.instance
          .getActiveTripById(widget.tripId);
      if (activeTrip == null) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        context.pop(); // close loader
        throw Exception(l10n.messengerRouteNotFound);
      }

      final bookingStr = await FirestoreDataRepository.instance.getBookingById(
        activeTrip.bookingId,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.pop(); // close loader

      if (bookingStr == null) {
        throw Exception(l10n.messengerBookingNotFound);
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.messengerParticipantsTitle,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildParticipantTile(
                  name: AuthService.instance.appUser?.name?.isNotEmpty == true
                      ? AuthService.instance.appUser!.name!
                      : l10n.messengerRoleOrganizer,
                  role: l10n.messengerRoleOrganizer,
                  icon: LucideIcons.user,
                ),
                if (bookingStr.guideName != null &&
                    bookingStr.guideName!.isNotEmpty)
                  _buildParticipantTile(
                    name: bookingStr.guideName!,
                    role: l10n.messengerRoleGuide,
                    icon: LucideIcons.userCheck,
                    onTap: () async {
                      if (bookingStr.guideId != null) {
                        final partner = await FirestoreDataRepository.instance
                            .streamPartner(bookingStr.guideId!)
                            .first;
                        if (partner != null && context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) =>
                                PartnerProfileSheet(profile: partner),
                          );
                        }
                      }
                    },
                  ),
                if (bookingStr.driverName != null &&
                    bookingStr.driverName!.isNotEmpty)
                  _buildParticipantTile(
                    name: bookingStr.driverName!,
                    role: l10n.messengerRoleDriver,
                    icon: LucideIcons.car,
                    onTap: () async {
                      if (bookingStr.driverId != null) {
                        final partner = await FirestoreDataRepository.instance
                            .streamPartner(bookingStr.driverId!)
                            .first;
                        if (partner != null && context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) =>
                                PartnerProfileSheet(profile: partner),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.pop(); // close loader if failed
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.messengerParticipantsLoadError(e.toString()))));
    }
  }

  Widget _buildParticipantTile({
    required String name,
    required String role,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.accent, size: 22),
      ),
      title: Text(name,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(role, style: TextStyle(color: AppColors.textSecondary)),
      trailing: onTap != null
          ? Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textSecondary)
          : null,
      onTap: onTap,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateLabel(DateTime dt) {
    final label = DateFormat('d MMMM', 'ru').format(dt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(left: 4, right: 12, top: topPad + 6, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              LucideIcons.arrowLeft,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              LucideIcons.user,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  AppLocalizations.of(context)!.messengerChatSubtitle,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              LucideIcons.moreVertical,
              color: AppColors.textSecondary,
              size: 20,
            ),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'participants') {
                _showParticipantsDialog();
              } else if (value == 'delete') {
                // Delete logic placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.messengerDeleteChatUnavailable),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'participants',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                        AppLocalizations.of(context)!.messengerViewParticipants,
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.messengerDeleteChat,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    required String time,
  }) {
    // My messages: blue bubble, white text — right side
    // Their messages: white bubble, black text — left side
    final myBubbleColor = AppColors.accent;
    final theirBubbleColor = AppColors.surface;
    final myTextColor = Colors.white;
    final theirTextColor = AppColors.textPrimary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 64 : 0,
        right: isMe ? 0 : 64,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.user,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? myBubbleColor : theirBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? myTextColor : theirTextColor,
                      fontSize: 15,
                      height: 1.38,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: bottomPad + 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  LucideIcons.paperclip,
                  color: Color(0xFFAAAAAA),
                  size: 22,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.messengerInputHint,
                      hintStyle: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 19,
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

