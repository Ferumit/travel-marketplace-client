import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/firebase_auth_module.dart';
import '../widgets/safe_network_image.dart';
import '../l10n/app_localizations.dart';

enum _AuthTab { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  _AuthTab _tab = _AuthTab.login;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchTab(_AuthTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    _fadeCtrl.forward(from: 0.4);
  }

  // ── Логика авторизации ────────────────────────────────────────────────────

  Future<void> _submit() async {
    AuthService.instance.setAuthInProgress(true);
    try {
      if (AuthService.bypassFirebaseInitAndAuth) {
        setState(() => _isLoading = true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() => _isLoading = false);
        await AuthService.instance.completeRegistration();
        return;
      }

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(AppLocalizations.of(context)!.authFillEmailPassword);
      return;
    }

    setState(() => _isLoading = true);

    final AuthResult result;
    if (_tab == _AuthTab.login) {
      result = await FirebaseAuthModule.signInWithEmail(
        email: email,
        password: password,
      );
    } else {
      result = await FirebaseAuthModule.registerWithEmail(
        email: email,
        password: password,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final user = result.user;

      if (_tab == _AuthTab.register) {
        // Отправляем письмо и разлогиниваем, чтобы пользователь вошел только после подтверждения
        final verifyRes = await FirebaseAuthModule.sendEmailVerification();
        await FirebaseAuthModule.signOut();

        if (verifyRes.success) {
          await _showSuccessDialog(
            'Регистрация почти завершена',
            'Вам на почту отправлена ссылка. Пожалуйста, перейдите по ней для подтверждения, а затем войдите в аккаунт.',
          );
          _switchTab(_AuthTab.login);
        } else {
          _showError(verifyRes.errorMessage ?? 'Не удалось отправить письмо для подтверждения.');
        }
      } else if (_tab == _AuthTab.login && user != null && !user.emailVerified) {
        // Запрещаем вход, если почта не подтверждена
        await FirebaseAuthModule.signOut();
        await _showUnverifiedEmailDialog();
      } else {
        await AuthService.instance.completeRegistration();
      }
    } else {
      _showError(
        result.errorMessage ?? AppLocalizations.of(context)!.authUnknownError,
      );
    }
    } finally {
      AuthService.instance.setAuthInProgress(false);
    }
  }

  Future<void> _showSuccessDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnverifiedEmailDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Подтвердите почту', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Пожалуйста, перейдите по ссылке в письме, чтобы подтвердить ваш email. Если вы не получили письмо, мы можем отправить его снова.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              AuthService.instance.setAuthInProgress(true);
              
              try {
                // Для отправки письма нужен текущий пользователь, поэтому логинимся временно
                final email = _emailCtrl.text.trim();
                final password = _passwordCtrl.text;
                
                final res = await FirebaseAuthModule.signInWithEmail(email: email, password: password);
                if (res.success) {
                  await FirebaseAuthModule.sendEmailVerification();
                  await FirebaseAuthModule.signOut();
                  if (mounted) {
                    await _showSuccessDialog('Письмо отправлено', 'Проверьте вашу почту.');
                  }
                } else {
                  if (mounted) {
                    _showError('Не удалось войти для отправки письма: ${res.errorMessage}');
                  }
                }
              } finally {
                AuthService.instance.setAuthInProgress(false);
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Отправить еще раз'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitGoogle() async {
    setState(() => _isLoading = true);
    AuthService.instance.setAuthInProgress(true);
    try {
      final result = await FirebaseAuthModule.signInWithGoogle()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        return AuthResult.fail('Превышено время ожидания Google Sign-In');
      });
      if (!mounted) return;
      if (result.success) {
        final user = FirebaseAuth.instance.currentUser;
        final hasPassword = user?.providerData.any((p) => p.providerId == 'password') ?? false;

        if (user != null && !hasPassword) {
          final password = await _showSetPasswordDialog();
          if (password != null && password.isNotEmpty) {
            try {
              await user.updatePassword(password);
            } catch (e) {
              _showError('Не удалось установить пароль: $e');
            }
          }
        }
        await AuthService.instance.completeRegistration();
      } else {
        if (result.errorMessage != 'Авторизация отменена') {
          _showError(
            result.errorMessage ??
                AppLocalizations.of(context)!.authGoogleError,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка Google: $e');
    } finally {
      AuthService.instance.setAuthInProgress(false);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Фон: фото ───────────────────────────────────────────────────────
          Positioned.fill(
            child: const SafeNetworkImage(
              url:
                  'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1080&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          // Градиент поверх фона
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.60),
                    AppColors.background.withValues(alpha: 0.97),
                  ],
                ),
              ),
            ),
          ),
          // ── Контент ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Лого + название
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'lib/assets/images/icon.png',
                                  color: const Color(0xFF0B1209),
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(LucideIcons.compass,
                                          color: Color(0xFF0B1209), size: 36),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Explora',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Открывайте новые горизонты',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Переключатель табов
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusXl),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _buildTab(
                              title: 'Вход',
                              tab: _AuthTab.login,
                            ),
                            _buildTab(
                              title: 'Регистрация',
                              tab: _AuthTab.register,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Поля ввода
                      if (_tab == _AuthTab.register) ...[
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Имя',
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _passwordCtrl,
                        label: 'Пароль',
                        icon: LucideIcons.lock,
                        obscureText: _obscurePassword,
                        suffix: GestureDetector(
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: AppColors.textTertiary,
                            size: 18,
                          ),
                        ),
                      ),

                      // Забыли пароль?
                      if (_tab == _AuthTab.login) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showPasswordReset,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Забыли пароль?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        const SizedBox(height: 32),
                      ],

                      // Кнопка Submit
                      _buildSubmitButton(),
                      const SizedBox(height: 24),

                      // Разделитель
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ИЛИ',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Кнопка Google
                      _buildGoogleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required _AuthTab tab}) {
    final isSelected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(tab),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusXl),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            style: TextStyle(
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: AppColors.textTertiary, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: suffix,
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: _isLoading
              ? AppColors.accent.withValues(alpha: 0.6)
              : AppColors.accent,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _tab == _AuthTab.login ? 'Войти' : 'Создать аккаунт',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitGoogle,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo SVG inline
            SizedBox(
              width: 20,
              height: 20,
              child: Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                errorBuilder: (_, __, ___) => const Icon(
                  LucideIcons.globe,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Войти через Google',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordReset() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Сброс пароля',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите ваш Email, и мы отправим ссылку для сброса пароля.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    final text = emailCtrl.text.trim();
    emailCtrl.dispose();

    if (confirmed == true && mounted) {
      final result = await FirebaseAuthModule.sendPasswordReset(text);
      if (!mounted) return;
      if (result.success) {
        _showSuccessDialog('Письмо отправлено', 'Проверьте вашу почту для сброса пароля.');
      } else {
        _showError(result.errorMessage ?? 'Ошибка отправки');
      }
    }

    emailCtrl.dispose();
  }

  Future<String?> _showSetPasswordDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _SetPasswordDialog(),
    );
  }
}

class _SetPasswordDialog extends StatefulWidget {
  const _SetPasswordDialog();

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Создайте пароль', style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Чтобы в будущем вы могли войти по Email или удалить аккаунт, придумайте пароль.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Новый пароль',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Пропустить', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_passwordCtrl.text.length >= 6) {
              Navigator.pop(context, _passwordCtrl.text);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пароль должен содержать минимум 6 символов')),
              );
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
