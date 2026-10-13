import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/offline_models.dart';
import '../models/sos_signal.dart';
import '../repository/firestore_data_repository.dart';
import 'connectivity_service.dart';

/// Сервис для гибридной доставки SOS-сигнала.
///
/// Логика работы:
/// 1. При нажатии SOS: BLE-маяк включён в [MeshService].
/// 2. Если есть интернет — немедленно записывает в Firestore.
/// 3. Если нет — добавляет в pending-очередь (SharedPreferences).
/// 4. При появлении интернета — автоматически сбрасывает очередь.
///
/// Relay-логика:
/// Когда другой участник получает SOS по BLE, он вызывает [relayReceivedSos],
/// который также пытается записать сигнал (дедупликация по [signalId]).
class SosService {
  SosService._();
  static final SosService instance = SosService._();

  static const _prefKey = 'sos_pending_queue';

  bool _initialized = false;
  // Флаг защиты от параллельного запуска flush (BUG-6 fix)
  bool _isFlushing = false;
  // Retry-таймер: повторяет попытку сброса очереди каждые 30с при отсутствии интернета
  Timer? _retryTimer;

  /// Инициализировать: подписаться на ConnectivityService для автосброса очереди.
  void init() {
    if (_initialized) return;
    _initialized = true;
    // BUG-1 fix: только один addListener через именованный метод
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (ConnectivityService.instance.isOnline) {
      _flushPendingQueue();
    }
  }

  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    _retryTimer?.cancel();
    _retryTimer = null;
    _initialized = false;
  }

  // ─── Публичный API ────────────────────────────────────────────────────────

  /// Генерирует стабильный signalId для SOS-сессии.
  ///
  /// BUG-2 fix: отправитель и relay используют ОДИНАКОВЫЙ детерминированный
  /// алгоритм (UUID v5), чтобы их записи в Firestore совпадали по ID.
  /// Округление до минуты: один SOS за минуту от одного user = один документ.
  static String deriveSignalId(String userId, DateTime ts) {
    final minuteTs = (ts.millisecondsSinceEpoch ~/ 60000) * 60000;
    // ignore: deprecated_member_use
    return const Uuid().v5(Uuid.NAMESPACE_URL, '$userId-$minuteTs');
  }

  /// Вызывается при нажатии SOS пользователем (только ОДИН раз при активации).
  ///
  /// BUG-3 fix: вызывается только при первой активации, не при каждом beacon ping.
  Future<void> sendSos({
    required String signalId,
    required String senderId,
    required String senderName,
    String? tripId,
    double? lat,
    double? lng,
    required DateTime sentAt,
  }) async {
    final signal = SosSignal(
      signalId: signalId,
      senderId: senderId,
      senderName: senderName,
      tripId: tripId,
      lat: lat,
      lng: lng,
      sentAt: sentAt,
      uploadedAt: DateTime.now(),
      uploadedBy: senderId,
      isRelay: false,
      status: 'active',
    );

    debugPrint('[SosService] 🆘 SOS от $senderName | signalId=$signalId | tripId=$tripId');

    if (ConnectivityService.instance.isOnline) {
      await _uploadToFirestore(signal);
    } else {
      debugPrint('[SosService] 📴 Нет интернета — сигнал добавлен в очередь');
      await _enqueue(signal);
    }
  }

  /// Вызывается при получении чужого SOS-сигнала через BLE Mesh.
  Future<void> relayReceivedSos({
    required OfflineMessage msg,
    required String relayUserId,
  }) async {
    if (msg.beaconActive != true) return;
    // BUG-5 fix: не relay собственный сигнал
    if (msg.userId == relayUserId) return;

    // BUG-2 fix: тот же алгоритм генерации signalId что и у отправителя
    final signalId = deriveSignalId(msg.userId, msg.timestamp);

    final signal = SosSignal(
      signalId: signalId,
      senderId: msg.userId,
      senderName: msg.userName,
      tripId: msg.tripId.isNotEmpty ? msg.tripId : null,
      lat: msg.lat,
      lng: msg.lng,
      sentAt: msg.timestamp,
      uploadedAt: DateTime.now(),
      uploadedBy: relayUserId,
      isRelay: true,
      status: 'active',
    );

    debugPrint('[SosService] 📡 Relay SOS от ${msg.userName} | signalId=$signalId');

    if (ConnectivityService.instance.isOnline) {
      await _uploadToFirestore(signal);
    } else {
      await _enqueue(signal);
    }
  }

  // ─── Внутренняя логика ────────────────────────────────────────────────────

  /// Загружает сигнал в Firestore. Игнорирует ошибку дубля.
  Future<void> _uploadToFirestore(SosSignal signal) async {
    try {
      await FirestoreDataRepository.instance.uploadSosSignal(signal);
      debugPrint('[SosService] ✅ Сигнал ${signal.signalId} записан в Firestore');
    } catch (e, stack) {
      // Документ уже существует (другой relay записал раньше) — ожидаемо.
      debugPrint('[SosService] ⚠️ Запись не удалась (возможно дубль): $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'SosService._uploadToFirestore', fatal: false);
    }
  }

  /// Помещает сигнал в pending-очередь (SharedPreferences).
  Future<void> _enqueue(SosSignal signal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefKey) ?? [];
      // BUG-4 fix: создаём новый Map вместо мутации результата toJson()
      final json = <String, dynamic>{...signal.toJson()};
      json['sentAt'] = signal.sentAt.millisecondsSinceEpoch;
      json['uploadedAt'] = signal.uploadedAt.millisecondsSinceEpoch;
      raw.add(jsonEncode(json));
      await prefs.setStringList(_prefKey, raw);
      debugPrint('[SosService] 💾 В очереди ${raw.length} сигналов');

      // Запускаем retry-таймер если ещё не запущен
      _retryTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
        debugPrint('[SosService] 🔄 Retry flush pending queue...');
        _flushPendingQueue();
      });
    } catch (e, stack) {
      debugPrint('[SosService] ❌ Ошибка enqueue: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'SosService._enqueue', fatal: false);
    }
  }

  /// Сбрасывает все накопленные сигналы в Firestore при появлении интернета.
  Future<void> _flushPendingQueue() async {
    // BUG-6 fix: защита от параллельного запуска
    if (_isFlushing) return;
    _isFlushing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefKey);
      if (raw == null || raw.isEmpty) return;

      debugPrint('[SosService] 🔄 Сброс ${raw.length} сигналов из очереди...');
      final remaining = <String>[];

      for (final item in raw) {
        try {
          final json = Map<String, dynamic>.from(jsonDecode(item) as Map);
          // Восстанавливаем int timestamp в ISO строку для SosSignal.fromJson
          final sentAtMs = json['sentAt'];
          final uploadedAtMs = json['uploadedAt'];
          if (sentAtMs is int) {
            json['sentAt'] = DateTime.fromMillisecondsSinceEpoch(sentAtMs).toIso8601String();
          }
          if (uploadedAtMs is int) {
            json['uploadedAt'] =
                DateTime.fromMillisecondsSinceEpoch(uploadedAtMs).toIso8601String();
          }
          final signal = SosSignal.fromJson(json);
          await _uploadToFirestore(signal);
        } catch (e, stack) {
          debugPrint('[SosService] ❌ Ошибка при сбросе сигнала: $e');
          FirebaseCrashlytics.instance.recordError(e, stack, reason: 'SosService._flushPendingQueue item', fatal: false);
          remaining.add(item);
        }
      }

      if (remaining.isEmpty) {
        await prefs.remove(_prefKey);
        _retryTimer?.cancel();
        _retryTimer = null;
        debugPrint('[SosService] ✅ Очередь полностью сброшена');
      } else {
        await prefs.setStringList(_prefKey, remaining);
        debugPrint('[SosService] ⚠️ Осталось ${remaining.length} в очереди');
      }
    } catch (e, stack) {
      debugPrint('[SosService] ❌ Ошибка flushPendingQueue: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'SosService._flushPendingQueue', fatal: false);
    } finally {
      _isFlushing = false;
    }
  }
}
