import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/user_models.dart' as app_models;
import '../repository/firestore_data_repository.dart';
import '../services/firebase_storage_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_widgets.dart';
import '../widgets/safe_network_image.dart';
import '../l10n/app_localizations.dart';
import '../utils/support_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingAvatar = false;
  bool _isUploadingAlbum = false;

  void _showAddPhotoModal(String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    LucideIcons.user,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profileUpdatePhoto,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    context.pop();
                    _uploadAvatar(uid);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    LucideIcons.imagePlus,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profileAddPhotoToAlbum,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    context.pop();
                    _uploadAlbumPhoto(uid);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadAvatar(String uid) async {
    setState(() => _isUploadingAvatar = true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = await FirebaseStorageService.instance.pickAndUploadImage(
      storagePath: 'users/$uid/avatar_$timestamp.jpg',
    );
    if (url != null) {
      await FirestoreDataRepository.instance.updateUserProfilePhoto(uid, url);
    }
    if (mounted) setState(() => _isUploadingAvatar = false);
  }

  Future<void> _uploadAlbumPhoto(String uid) async {
    setState(() => _isUploadingAlbum = true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = await FirebaseStorageService.instance.pickAndUploadImage(
      storagePath: 'users/$uid/album/photo_$timestamp.jpg',
    );
    if (url != null) {
      await FirestoreDataRepository.instance.addAlbumPhoto(uid, url);
    }
    if (mounted) setState(() => _isUploadingAlbum = false);
  }

  void _showAddCardDialog(String uid, String? currentCard) {
    final cardCtrl = TextEditingController(text: currentCard ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text(
          'Карта для оплаты',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите номер карты, с которой будут списываться средства за поездки.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cardCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '0000 0000 0000 0000',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLength: 16,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сохранить'),
            onPressed: () async {
              final val = cardCtrl.text.replaceAll(' ', '');
              if (val.length >= 12) {
                await FirestoreDataRepository.instance.updateUserData(uid, {
                  'savedCard': val,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authAppUser = AuthService.instance.appUser;
    final fbUser = AuthService.instance.currentFirebaseUser;

    if (fbUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            l10n.profileUserNotAuthorized,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Шапка ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    l10n.settingsProfile,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Контент профиля ─────────────────────────────────────────
            Expanded(
              child: StreamBuilder<app_models.User?>(
                stream: FirestoreDataRepository.instance.streamUser(fbUser.uid),
                builder: (context, snapshot) {
                  final dbUser = snapshot.data;
                  final appUser = dbUser ?? authAppUser;

                  final displayPhoto =
                      dbUser?.photoUrl ?? fbUser.photoUrl ?? appUser?.photoUrl;

                  String displayName =
                      'user№${fbUser.uid.substring(fbUser.uid.length - 6)}';
                  if (dbUser != null) {
                    if (dbUser.firstName != null &&
                        dbUser.firstName!.isNotEmpty) {
                      displayName = dbUser.firstName!;
                      if (dbUser.lastName != null &&
                          dbUser.lastName!.isNotEmpty) {
                        displayName += ' ${dbUser.lastName!}';
                      }
                    } else if (dbUser.name != null && dbUser.name!.isNotEmpty) {
                      displayName = dbUser.name!;
                    }
                  } else if (appUser != null &&
                      appUser.name != null &&
                      appUser.name!.isNotEmpty) {
                    displayName = appUser.name!;
                  }

                  final displayEmail = fbUser.email ??
                      fbUser.phoneNumber ??
                      appUser?.email ??
                      appUser?.phoneNumber ??
                      '';

                  final userPhone =
                      appUser?.phoneNumber ?? fbUser.phoneNumber ?? '';
                  final albumUrls = dbUser?.albumUrls ?? [];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
                    children: [
                      // ── Header с фото ─────────────────────────────────
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceMuted,
                                  border: Border.all(color: AppColors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: displayPhoto != null
                                    ? SafeNetworkImage(
                                        url: displayPhoto,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        LucideIcons.user,
                                        size: 36,
                                        color: AppColors.textSecondary,
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showAddPhotoModal(fbUser.uid),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.background,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: _isUploadingAvatar
                                        ? const Padding(
                                            padding: EdgeInsets.all(4.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            LucideIcons.plus,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayEmail,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Привязанная карта ─────────────────────────────
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusSm,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.creditCard,
                                    color: AppColors.accentBright,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    userPhone.isNotEmpty
                                        ? userPhone
                                        : 'Нет номера',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Карта для оплаты',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (appUser?.savedCard != null &&
                                appUser!.savedCard!.length >= 4)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '**** ${appUser.savedCard!.substring(appUser.savedCard!.length - 4)}',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showAddCardDialog(
                                      fbUser.uid,
                                      appUser.savedCard,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.accentBright,
                                    ),
                                    child: const Text('Изменить'),
                                  ),
                                ],
                              )
                            else
                              GestureDetector(
                                onTap: () => _showAddCardDialog(
                                  fbUser.uid,
                                  null,
                                ),
                                child: const Text(
                                  'Добавить карту',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Сетка меню ────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildMenuButton(
                              icon: LucideIcons.history,
                              label: l10n.profileMyOrders,
                              onTap: () => context.push('/my-orders'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMenuButton(
                              icon: LucideIcons.heart,
                              label: l10n.profileFavorites,
                              onTap: () => context.push('/favorites'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMenuButton(
                              icon: LucideIcons.fileText,
                              label: l10n.profileDocuments,
                              onTap: () => context.push('/documents'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMenuButton(
                              icon: LucideIcons.settings,
                              label: l10n.settingsTitle,
                              onTap: () => context.push('/settings'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMenuButton(
                              icon: LucideIcons.siren,
                              label: 'SOS История',
                              onTap: () => context.push('/sos-history'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Поддержка ─────────────────────────────────────
                      const SectionHeader(title: 'ПОДДЕРЖКА'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMenuButton(
                              icon: LucideIcons.messageCircle,
                              label: 'Telegram',
                              onTap: () => SupportHelper.openTelegram(),
                              height: 100,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMenuButton(
                              icon: LucideIcons.phone,
                              label: 'WhatsApp',
                              onTap: () => SupportHelper.openWhatsApp(),
                              height: 100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Альбом ────────────────────────────────────────
                      SectionHeader(
                        title: 'МОЙ АЛЬБОМ',
                        padding: EdgeInsets.zero,
                        actionLabel: _isUploadingAlbum ? 'Загрузка...' : null,
                      ),
                      const SizedBox(height: 16),
                      if (albumUrls.isEmpty)
                        AppEmptyState(
                          icon: LucideIcons.imagePlus,
                          title: l10n.profileNoPhotosYet,
                          subtitle: l10n.profileAddMemories,
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: albumUrls.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusSm),
                              child: SafeNetworkImage(
                                url: albumUrls[index],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),

                      // ── Выход ─────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => AuthService.instance.signOut(),
                          icon: const Icon(LucideIcons.logOut, size: 20),
                          label: Text(l10n.profileLogout),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double height = 130,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


