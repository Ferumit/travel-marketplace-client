import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/firebase_auth_module.dart';
import '../models/user_models.dart' as app_models;
import '../repository/firestore_data_repository.dart';

/// Синглтон-сервис авторизации.
///
/// Координирует два источника истины:
///   • [FirebaseAuthModule] — реальное состояние Firebase Auth
///   • [SharedPreferences]  — онбординг-флаг (не хранится в Firebase)
///
/// GoRouter слушает [notifier] и переспрашивает [redirect] при любом изменении.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Ключ SharedPreferences для конкретного UID. Онбординг хранится per-user.
  static String _keyOnboarded(String uid) => 'auth_is_onboarded_$uid';
  /// Устаревший ключ (без UID) — читаем для миграции.
  static const _legacyKeyOnboarded = 'auth_is_onboarded';

  bool _isOnboarded = false;
  bool get isOnboarded => _isOnboarded;

  bool _isAuthInProgress = false;
  bool get isAuthInProgress => _isAuthInProgress;

  void setAuthInProgress(bool value) {
    _isAuthInProgress = value;
    notifyListeners();
  }

  // 🔴 TODO: ДЛЯ РЕЛИЗА И ВКЛЮЧЕНИЯ FIREBASE переведите этот флаг в `false`
  static const bool bypassFirebaseInitAndAuth = false;

  // Локальный стейт, чтобы приложение думало, что пользователь вошел (пока Firebase выключен)
  bool _mockIsRegistered = false;

  /// `true` если Firebase вернул текущего пользователя (или включен байпасс).
  bool get isRegistered => bypassFirebaseInitAndAuth
      ? _mockIsRegistered
      : FirebaseAuthModule.currentUser != null;

  /// Текущий профиль пользователя из Firestore (null если не авторизован).
  app_models.User? _appUser;
  app_models.User? get appUser => bypassFirebaseInitAndAuth
      ? const app_models.User(
          id: 'mock_uid_123',
          email: 'test@example.kz',
          name: 'Тестовый Пользователь',
          phoneNumber: '+70000000000',
          balance: 15000.0,
          trustedContacts: [],
          isGuest: false,
        )
      : _appUser;

  /// Текущий Firebase-пользователь (null если не авторизован).
  FirebaseUserModel? get currentFirebaseUser => bypassFirebaseInitAndAuth
      ? const FirebaseUserModel(
          uid: 'mock_uid_123',
          email: 'test@example.kz',
          displayName: 'Тестовый Пользователь',
          phoneNumber: '+70000000000',
        )
      : FirebaseAuthModule.currentUser;

  /// Загружает сохранённое состояние. Вызывать один раз в `main()`.
  Future<void> init() async {
    // Изначально флаг неизвестен — выставим false до прихода authStateChanges
    _isOnboarded = false;

    // Слушаем изменения Firebase Auth — при входе/выходе перестраиваем маршруты
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        // 1. Загружаем онбординг-флаг для конкретного пользователя
        final prefs = await SharedPreferences.getInstance();
        final uid = firebaseUser.uid;
        // Читаем per-user ключ; для старых установок проверяем устаревший ключ
        final done = prefs.getBool(_keyOnboarded(uid))
            ?? prefs.getBool(_legacyKeyOnboarded)
            ?? false;
        // Если нашли по устаревшему ключу — мигрируем
        if (done && prefs.getBool(_keyOnboarded(uid)) == null) {
          await prefs.setBool(_keyOnboarded(uid), true);
          await prefs.remove(_legacyKeyOnboarded);
        }
        _isOnboarded = done;

        // 2. Пытаемся загрузить юзера из Firestore
        var userDoc = await FirestoreDataRepository.instance.getUser(uid);
        if (userDoc == null) {
          // 3. Новая регистрация — создаём профиль
          userDoc = app_models.User(
            id: uid,
            phoneNumber: firebaseUser.phoneNumber ?? '',
            email: firebaseUser.email,
            name: firebaseUser.displayName,
            balance: 0.0,
            trustedContacts: [],
            isGuest: false,
          );
          await FirestoreDataRepository.instance.saveUser(userDoc);
        } else if (userDoc.isPendingDeletion) {
          // 4. Восстанавливаем аккаунт, помеченный на удаление
          await FirestoreDataRepository.instance.cancelUserDeletion(uid);
          userDoc = userDoc.copyWith(deletionRequestedAt: null);
          debugPrint('[AuthService] Аккаунт $uid восстановлен при входе.');
        }
        _appUser = userDoc;
      } else {
        _appUser = null;
        _isOnboarded = false; // сброс только локального стейта, не SharedPrefs
      }

      if (!bypassFirebaseInitAndAuth && !_isAuthInProgress) notifyListeners();
    });

    notifyListeners();
  }

  /// Вызывать после успешной регистрации/входа через [FirebaseAuthModule].
  Future<void> completeRegistration() async {
    if (bypassFirebaseInitAndAuth) {
      _mockIsRegistered = true;
    }
    // Firebase уже обновил currentUser — просто уведомляем GoRouter
    notifyListeners();
  }

  /// Вызывать после завершения онбординга.
  Future<void> completeOnboarding() async {
    _isOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuthModule.currentUser?.uid;
    if (uid != null) {
      await prefs.setBool(_keyOnboarded(uid), true);
    }
    notifyListeners();
  }

  /// Полный выход — Firebase Auth. Онбординг-флаг НЕ сбрасывается
  /// (он per-user, поэтому при следующем входе пользователь не увидит онбординг снова).
  Future<void> signOut() async {
    if (bypassFirebaseInitAndAuth) {
      _mockIsRegistered = false;
    } else {
      await FirebaseAuthModule.signOut();
    }
    // _isOnboarded сбросится автоматически через authStateChanges (firebaseUser == null)
    notifyListeners();
  }

  /// Удаление текущего аккаунта пользователя (отложенное на 30 дней).
  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Помечаем в Firestore (устанавливаем deletionRequestedAt)
        await FirestoreDataRepository.instance.markUserForDeletion(user.uid);
        
        // Выходим из аккаунта
        await signOut();
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Ошибка удаления аккаунта: ${e.message}');
    } catch (e) {
      throw Exception('Неизвестная ошибка удаления: $e');
    }
  }
}

