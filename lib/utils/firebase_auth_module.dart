import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Модели
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseUserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  const FirebaseUserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  factory FirebaseUserModel._fromFirebase(User user) => FirebaseUserModel(
    uid: user.uid,
    email: user.email,
    phoneNumber: user.phoneNumber,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    emailVerified: user.emailVerified,
  );

  @override
  String toString() =>
      'FirebaseUserModel(uid: $uid, email: $email, emailVerified: $emailVerified)';
}

/// Результат операции авторизации — всегда возвращается, никогда не бросает.
class AuthResult {
  /// `true` — операция выполнена успешно.
  final bool success;

  /// Пользователь при успехе, иначе `null`.
  final FirebaseUserModel? user;

  /// Читаемое сообщение об ошибке (на русском) при `success == false`.
  final String? errorMessage;

  const AuthResult._({required this.success, this.user, this.errorMessage});

  factory AuthResult.ok(FirebaseUserModel user) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.fail(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

// ─────────────────────────────────────────────────────────────────────────────
// Модуль
// ─────────────────────────────────────────────────────────────────────────────

/// Отказоустойчивый модуль Firebase Authentication.
///
/// • Email/Password — регистрация и вход
/// • Все методы оборачивают [FirebaseAuthException] в [AuthResult.fail]
///   с понятным текстом на русском языке
/// • Не зависит от SharedPreferences / AuthService — чистый слой доступа к Firebase
///
/// Готов к замене на FastAPI-клиент: достаточно поменять реализацию методов,
/// не трогая вызывающий код.
abstract final class FirebaseAuthModule {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Текущий пользователь ──────────────────────────────────────────────────

  /// Текущий пользователь Firebase, `null` если не авторизован.
  static FirebaseUserModel? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : FirebaseUserModel._fromFirebase(u);
  }

  /// Stream состояния авторизации — эмитирует при каждом входе/выходе.
  static Stream<FirebaseUserModel?> get authStateChanges => _auth
      .authStateChanges()
      .map((u) => u == null ? null : FirebaseUserModel._fromFirebase(u));

  // ── Регистрация ───────────────────────────────────────────────────────────

  /// Регистрирует нового пользователя по [email] и [password].
  ///
  /// Возвращает [AuthResult.ok] при успехе,
  /// [AuthResult.fail] с читаемым сообщением при любой ошибке.
  static Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return AuthResult.fail('Не удалось создать пользователя');
      }
      debugPrint('[FirebaseAuthModule] Registered: ${user.uid}');
      return AuthResult.ok(FirebaseUserModel._fromFirebase(user));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[FirebaseAuthModule] Register error: ${e.code} — ${e.message}',
      );
      return AuthResult.fail(_mapError(e.code));
    } catch (e, stack) {
      debugPrint('[FirebaseAuthModule] Unknown register error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.registerWithEmail', fatal: false);
      return AuthResult.fail('Произошла непредвиденная ошибка');
    }
  }

  // ── Вход ──────────────────────────────────────────────────────────────────

  /// Вход по [email] и [password].
  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return AuthResult.fail('Не удалось выполнить вход');
      }
      debugPrint('[FirebaseAuthModule] Signed in: ${user.uid}');
      return AuthResult.ok(FirebaseUserModel._fromFirebase(user));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[FirebaseAuthModule] Sign-in error: ${e.code} — ${e.message}',
      );
      return AuthResult.fail(_mapError(e.code));
    } catch (e, stack) {
      debugPrint('[FirebaseAuthModule] Unknown sign-in error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.signInWithEmail', fatal: false);
      return AuthResult.fail('Произошла непредвиденная ошибка');
    }
  }

  // ── Вход через Google ──────────────────────────────────────────────────────

  static bool _googleSignInInitialized = false;

  /// Вызов нативного окна входа через Google.
  static Future<AuthResult> signInWithGoogle() async {
    try {
      if (!_googleSignInInitialized) {
        // Указывается Web Client ID из google-services.json (client_type: 3),
        // чтобы обойти ошибку PlatformException при обрыве Pigeon channel.
        await GoogleSignIn.instance.initialize(
          serverClientId:
              '000000000000-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',
        );
        _googleSignInInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return AuthResult.fail('Не удалось выполнить вход через Google');
      }

      debugPrint('[FirebaseAuthModule] Google signed in: ${user.uid}');
      return AuthResult.ok(FirebaseUserModel._fromFirebase(user));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return AuthResult.fail('Авторизация отменена');
      }
      debugPrint(
        '[FirebaseAuthModule] Google sign-in exception: ${e.code} — ${e.description}',
      );
      return AuthResult.fail('Ошибка Google: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[FirebaseAuthModule] Google firebase error: ${e.code} — ${e.message}',
      );
      return AuthResult.fail(_mapError(e.code));
    } catch (e, stack) {
      debugPrint('[FirebaseAuthModule] Unknown Google sign-in error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.signInWithGoogle', fatal: false);
      return AuthResult.fail('Произошла ошибка при входе через Google');
    }
  }

  // ── Выход ──────────────────────────────────────────────────────────────────

  /// Выход из Firebase Auth. Отказоустойчив — never throws.
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[FirebaseAuthModule] Signed out');
    } catch (e, stack) {
      debugPrint('[FirebaseAuthModule] Error during sign out: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.signOut', fatal: false);
      // Намеренно игнорируем — пользователь всё равно должен выйти
    }
  }

  // ── Телефон (Phone Auth) ──────────────────────────────────────────────────

  /// Начинает процесс авторизации по номеру телефона.
  /// На Android/iOS это может отправить SMS.
  static Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String errorMessage) verificationFailed,
    required Function(FirebaseUserModel user) verificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            verificationCompleted(
              FirebaseUserModel._fromFirebase(userCredential.user!),
            );
          } else {
            verificationFailed('Не удалось авторизоваться автоматически');
          }
        } catch (e, stack) {
          FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.verifyPhone autoSignIn', fatal: false);
          verificationFailed('Ошибка автоматической авторизации');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint(
          '[FirebaseAuthModule] Phone auth failed: ${e.code} — ${e.message}',
        );
        verificationFailed(_mapError(e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Проверяет SMS-код и выполняет вход.
  static Future<AuthResult> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return AuthResult.fail('Не удалось выполнить вход');
      }
      debugPrint('[FirebaseAuthModule] Phone signed in: ${user.uid}');
      return AuthResult.ok(FirebaseUserModel._fromFirebase(user));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[FirebaseAuthModule] SMS verification error: ${e.code} — ${e.message}',
      );
      return AuthResult.fail(_mapError(e.code));
    } catch (e, stack) {
      debugPrint('[FirebaseAuthModule] Unknown SMS error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.verifySmsCode', fatal: false);
      return AuthResult.fail('Произошла непредвиденная ошибка');
    }
  }

  // ── Сброс пароля и подтверждение почты ─────────────────────────────────────

  /// Отправляет письмо для подтверждения почты.
  static Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult.ok(FirebaseUserModel._fromFirebase(user));
      }
      return AuthResult.fail('Пользователь не авторизован или почта уже подтверждена');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.sendEmailVerification', fatal: false);
      return AuthResult.fail('Ошибка отправки письма с подтверждением');
    }
  }

  /// Отправляет письмо для сброса пароля на [email].
  static Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[FirebaseAuthModule] Password reset sent to $email');
      return AuthResult.ok(
        const FirebaseUserModel(uid: '', emailVerified: false),
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseAuthModule.sendPasswordReset', fatal: false);
      return AuthResult.fail('Ошибка отправки письма');
    }
  }

  // ── Маппинг ошибок ────────────────────────────────────────────────────────

  static String _mapError(String code) => switch (code) {
    'invalid-email' => 'Некорректный email адрес',
    'invalid-phone-number' => 'Некорректный номер телефона',
    'invalid-verification-code' => 'Неверный код из SMS',
    'invalid-verification-id' => 'Сессия проверки устарела',
    'quota-exceeded' => 'Превышен лимит отправки SMS',
    'user-not-found' => 'Пользователь не найден',
    'wrong-password' ||
    'invalid-credential' => 'Неверный email, пароль или SMS-код',
    'email-already-in-use' => 'Этот email уже зарегистрирован',
    'weak-password' => 'Пароль должен содержать не менее 6 символов',
    'user-disabled' => 'Аккаунт заблокирован',
    'too-many-requests' => 'Слишком много попыток — попробуйте позже',
    'network-request-failed' => 'Нет подключения к интернету',
    'operation-not-allowed' =>
      'Данный способ входа не поддерживается в Firebase',
    'requires-recent-login' => 'Для этого действия нужно войти заново',
    _ => 'Ошибка авторизации ($code)',
  };
}

