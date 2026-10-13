import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/theme.dart';
import '../models/user_models.dart' as app_models;
import '../repository/firestore_data_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- STATE (Данные из React кода) ---
  bool _notificationsEnabled = true;

  app_models.User? _currentUser;
  bool _isLoadingUser = true;
  StreamSubscription<fb_auth.User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = fb_auth.FirebaseAuth.instance.authStateChanges().listen((
      fbUser,
    ) async {
      if (fbUser != null) {
        final userParams = await FirestoreDataRepository.instance.getUser(
          fbUser.uid,
        );
        if (context.mounted) {
          setState(() {
            _currentUser = userParams;
            _isLoadingUser = false;
          });
        }
      } else {
        if (context.mounted) {
          setState(() {
            _currentUser = null;
            _isLoadingUser = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // SOS Контакты
  final List<Map<String, dynamic>> _sosContacts = [
    {
      'id': 1,
      'name': 'Анна Соколова',
      'phone': '+7 (999) 111-22-33',
      'relation': 'wife',
    },
    {
      'id': 2,
      'name': 'Иван Петров',
      'phone': '+7 (999) 444-55-66',
      'relation': 'friend',
    },
    {
      'id': 3,
      'name': 'МЧС Горно-Алтайск',
      'phone': '+7 (388) 22-01-12',
      'relation': 'emergency',
    },
  ];

  String _getLocalizedRelation(String relation, AppLocalizations l10n) {
    return switch (relation) {
      'wife' => l10n.settingsRelationWife,
      'husband' => l10n.settingsRelationHusband,
      'friend' => l10n.settingsRelationFriend,
      'emergency' => l10n.settingsRelationEmergency,
      _ => relation,
    };
  }

  // Язык и Тема
  String _selectedLanguage = LocaleService.instance.locale.languageCode;
  String get _selectedThemeId {
    switch (ThemeService.instance.themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'auto';
    }
  }

  final List<Map<String, String>> _languages = [
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'kk', 'name': 'Қазақша', 'flag': '🇰🇿'},
  ];

  List<Map<String, String>> _getThemes(AppLocalizations l10n) => [
    {
      'id': 'dark',
      'name': l10n.settingsThemeDark,
      'desc': l10n.settingsThemeDarkDesc,
    },
    {
      'id': 'light',
      'name': l10n.settingsThemeLight,
      'desc': l10n.settingsThemeLightDesc,
    },
    {
      'id': 'auto',
      'name': l10n.settingsThemeAuto,
      'desc': l10n.settingsThemeAutoDesc,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final themes = _getThemes(l10n);
    final currentLangName = _languages.firstWhere(
      (l) => l['code'] == _selectedLanguage,
    )['name'];
    final currentThemeName = themes.firstWhere(
      (t) => t['id'] == _selectedThemeId,
    )['name'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _buildSection(
            title: l10n.settingsProfile,
            children: [
              _buildSettingItem(
                icon: LucideIcons.user,
                label: l10n.settingsPersonalData,
                value: _isLoadingUser
                    ? l10n.settingsLoading
                    : (_currentUser?.firstName ??
                          _currentUser?.name ??
                          l10n.settingsNotSpecified),
                onTap: () => _showPersonalDataSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: l10n.settingsSecurity,
            children: [
              _buildSettingItem(
                icon: LucideIcons.shield,
                label: l10n.settingsSosContacts,
                value: l10n.settingsContactsCount(_sosContacts.length),
                onTap: () => _showSosContactsSheet(context),
              ),
              _buildSettingItem(
                icon: LucideIcons.bell,
                label: l10n.settingsEmergencyAlerts,
                isToggle: true,
                toggleValue: _notificationsEnabled,
                onToggle: () {
                  setState(() {
                    _notificationsEnabled = !_notificationsEnabled;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: l10n.settingsApp,
            children: [
              _buildSettingItem(
                icon: LucideIcons.globe,
                label: l10n.settingsLanguage,
                value: currentLangName,
                onTap: () => _showLanguageSheet(context),
              ),
              _buildSettingItem(
                icon: LucideIcons.moon,
                label: l10n.settingsTheme,
                value: currentThemeName,
                onTap: () => _showThemeSheet(context, l10n),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: l10n.settingsAbout,
            children: [
              _buildSettingItem(
                icon: LucideIcons.info,
                label: l10n.settingsVersion,
                value: '1.0.10',
              ),
              // Политика конфиденциальности в стиле остальных элементов
              _buildSettingItem(
                icon: LucideIcons.fileText, // Или скрыть иконку если нужно
                label: l10n.settingsPrivacyLog,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService.instance.signOut();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(LucideIcons.logOut, size: 20),
              label: Text(l10n.settingsLogout),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.theme.colorScheme.error,
                side: BorderSide(
                  color: context.theme.colorScheme.error.withValues(alpha: 0.3),
                ),
                backgroundColor: context.theme.colorScheme.error.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteAccountDialog(context),
              icon: const Icon(LucideIcons.trash2, size: 20),
              label: Text(l10n.settingsDeleteAccount),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: context.theme.colorScheme.error),
                backgroundColor: context.theme.colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Session ID: 89f-2a1-99c',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- UI BUILDERS ---

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontFamily: 'Manrope',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface, // Slate-800
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    color: AppColors.border.withValues(alpha: 0.5),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    String? value,
    bool isToggle = false,
    bool toggleValue = false,
    VoidCallback? onToggle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isToggle ? onToggle : onTap,
      borderRadius: BorderRadius.circular(
        16,
      ), // Чтобы эффект нажатия не вылезал
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  fontFamily: 'Manrope',
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Manrope',
                ),
              ),
            const SizedBox(width: 8),

            if (isToggle)
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: toggleValue
                        ? AppColors.accent
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: toggleValue
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else if (onTap != null)
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  // --- MODALS (BOTTOM SHEETS) ---

  void _showPersonalDataSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_currentUser == null) return;

    final firstNameCtrl = TextEditingController(
      text: _currentUser!.firstName ?? _currentUser!.name ?? '',
    );
    final lastNameCtrl = TextEditingController(
      text: _currentUser!.lastName ?? '',
    );
    final emailCtrl = TextEditingController(text: _currentUser!.email ?? '');
    final phoneCtrl = TextEditingController(text: _currentUser!.phoneNumber);
    final birthDateCtrl = TextEditingController(
      text: _currentUser!.birthDate ?? '',
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildBottomSheetBase(
          title: l10n.settingsPersonalData,
          child: Column(
            children: [
              _buildInput(l10n.settingsFieldFirstName, controller: firstNameCtrl),
              _buildInput(l10n.settingsFieldLastName, controller: lastNameCtrl),
              _buildInput(
                l10n.settingsFieldEmail,
                controller: emailCtrl,
                inputType: TextInputType.emailAddress,
              ),
              _buildInput(
                l10n.settingsFieldPhone,
                controller: phoneCtrl,
                inputType: TextInputType.phone,
              ),
              _buildInput(
                l10n.settingsFieldBirthDate,
                controller: birthDateCtrl,
                readOnly: true,
                onTap: () async {
                  final dt = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 365 * 20),
                    ),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (dt != null) {
                    birthDateCtrl.text =
                        "\${dt.day.toString().padLeft(2, '0')}.\${dt.month.toString().padLeft(2, '0')}.\${dt.year}";
                  }
                },
              ),
              const SizedBox(height: 16),
              isSaving
                  ? CircularProgressIndicator(color: AppColors.accent)
                  : _buildPrimaryButton(l10n.settingsSaveChanges, () async {
                      setModalState(() => isSaving = true);
                      try {
                        await FirestoreDataRepository.instance
                            .updateUserData(_currentUser!.id, {
                              'firstName': firstNameCtrl.text.trim(),
                              'lastName': lastNameCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'phoneNumber': phoneCtrl.text.trim(),
                              'birthDate': birthDateCtrl.text.trim(),
                            });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.settingsDataSaved,
                              ),
                            ),
                          );
                          context.pop();
                          // Update local state manually right away since firestore subscription might be slow / one-shot depending on logic
                          final updatedUser = await FirestoreDataRepository
                              .instance
                              .getUser(_currentUser!.id);
                          setState(() => _currentUser = updatedUser);
                        }
                      } catch (e) {
                        debugPrint('Update error: $e');
                      } finally {
                        if (context.mounted) {
                          setModalState(() => isSaving = false);
                        }
                      }
                    }),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      firstNameCtrl.dispose();
      lastNameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      birthDateCtrl.dispose();
    });
  }

  void _showSosContactsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final contacts = _currentUser?.trustedContacts ?? [];

          Future<void> deleteContact(int index) async {
            if (_currentUser == null) return;
            final updated = List<app_models.TrustedContact>.from(contacts)
              ..removeAt(index);
            await FirestoreDataRepository.instance.updateUserData(
              _currentUser!.id,
              {'trustedContacts': updated.map((e) => e.toJson()).toList()},
            );
            final refreshed = await FirestoreDataRepository.instance
                .getUser(_currentUser!.id);
            setState(() => _currentUser = refreshed);
            setModalState(() {});
          }

          void openAddForm() {
            final nameCtrl = TextEditingController();
            final phoneCtrl = TextEditingController();
            String relation = 'friend';

            showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx2) => StatefulBuilder(
                builder: (ctx2, setFormState) => _buildBottomSheetBase(
                  title: l10n.settingsAddContact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInput(
                        l10n.settingsFieldFirstName,
                        controller: nameCtrl,
                        inputType: TextInputType.name,
                      ),
                      _buildInput(
                        'Номер телефона',
                        controller: phoneCtrl,
                        inputType: TextInputType.phone,
                        hintText: '+7 (___) ___-__-__',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Отношение',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in ['friend', 'wife', 'husband', 'emergency'])
                            GestureDetector(
                              onTap: () => setFormState(() => relation = r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: relation == r
                                      ? AppColors.accent
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: relation == r
                                        ? AppColors.accent
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  _getLocalizedRelation(r, l10n),
                                  style: TextStyle(
                                    color: relation == r
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildPrimaryButton('Сохранить', () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) return;
                        if (_currentUser == null) return;

                        final newContact = app_models.TrustedContact(
                          name: name,
                          phoneNumber: phone,
                        );
                        final updated = [
                          ...(_currentUser!.trustedContacts),
                          newContact,
                        ];
                        await FirestoreDataRepository.instance.updateUserData(
                          _currentUser!.id,
                          {
                            'trustedContacts':
                                updated.map((e) => e.toJson()).toList(),
                          },
                        );
                        final refreshed = await FirestoreDataRepository
                            .instance
                            .getUser(_currentUser!.id);
                        setState(() => _currentUser = refreshed);
                        setModalState(() {});
                        if (ctx2.mounted) Navigator.of(ctx2).pop();
                      }),
                    ],
                  ),
                ),
              ),
            ).whenComplete(() {
              nameCtrl.dispose();
              phoneCtrl.dispose();
            });
          }

          return _buildBottomSheetBase(
            title: l10n.settingsSosContacts,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsSosDeleteDesc,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (contacts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Контакты не добавлены',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contacts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final c = contacts[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    c.phoneNumber,
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                LucideIcons.trash2,
                                color: context.theme.colorScheme.error,
                              ),
                              onPressed: () => deleteContact(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: openAddForm,
                    icon: const Icon(LucideIcons.plus),
                    label: Text(l10n.settingsAddContact),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetBase(
        title: l10n.settingsSelectLanguage,
        child: Column(
          children: [
            for (var lang in _languages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildSelectableItem(
                  isSelected: _selectedLanguage == lang['code'],
                  onTap: () async {
                    final code = lang['code']!;
                    await LocaleService.instance.setLocale(Locale(code));
                    setState(() => _selectedLanguage = code);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildPrimaryButton(l10n.settingsApply, () => context.pop()),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, AppLocalizations l10n) {
    final themes = _getThemes(l10n);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetBase(
        title: l10n.settingsThemeTitle,
        child: Column(
          children: [
            for (var theme in themes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildSelectableItem(
                  isSelected: _selectedThemeId == theme['id'],
                  onTap: () {
                    final mode = theme['id'] == 'light'
                        ? ThemeMode.light
                        : theme['id'] == 'dark'
                            ? ThemeMode.dark
                            : ThemeMode.system;
                    ThemeService.instance.setThemeMode(mode);
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        theme['desc']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildPrimaryButton(l10n.settingsApplyButton, () => context.pop()),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetBase(
        title: l10n.settingsDeleteAccountTitle,
        child: Column(
          children: [
            Icon(
              LucideIcons.alertTriangle,
              color: context.theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settingsDeleteAccountDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      l10n.settingsCancel,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      context.pop();
                      try {
                        await AuthService.instance.deleteAccount();
                        if (context.mounted) context.go('/auth');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: context.theme.colorScheme.error,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.settingsDeleteButton,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS FOR MODALS ---

  Widget _buildBottomSheetBase({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        // viewInsets.bottom = keyboard height, padding.bottom = gesture bar
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.paddingOf(context).bottom +
            24,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label, {
    TextEditingController? controller,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: inputType,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildSelectableItem({
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            if (isSelected)
              Icon(LucideIcons.check, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

