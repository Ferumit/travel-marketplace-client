import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:bridgefy/bridgefy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

import '../models/offline_models.dart';

/// Bridgefy BLE transport for the MESH offline module.
///
/// Design:
/// - Singleton with explicit [reset] for session reuse.
/// - [start] awaits the async [bridgefyDidStart] callback via Completer.
/// - [broadcast] only fires when SDK is truly started.
class MeshTransport with BridgefyDelegate {
  MeshTransport._();
  static final MeshTransport instance = MeshTransport._();

  final _bridgefy = Bridgefy();

  final _msgCtrl   = StreamController<OfflineMessage>.broadcast();
  final _errorCtrl  = StreamController<String?>.broadcast();
  final _peerConnCtrl = StreamController<String>.broadcast(); // fired on BLE connect

  bool _started = false;
  String _roomId = '';
  String _userId = '';

  // Message dedup — BLE mesh retransmits packets via multiple paths
  final Set<String> _seenIds = {};
  static const _maxSeenIds = 200;

  // Completer resolves once bridgefyDidStart fires (or fails).
  Completer<bool>? _startCompleter;

  bool get isStarted => _started;

  Stream<OfflineMessage> get incomingMessages => _msgCtrl.stream;
  Stream<String?> get btError              => _errorCtrl.stream;
  /// Fires with peerUserId each time a BLE peer connects.
  Stream<String>  get peerConnected        => _peerConnCtrl.stream;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Resets state so the transport can be cleanly restarted.
  void reset() {
    _started = false;
    _roomId = '';
    _userId = '';
    _startCompleter = null;
  }

  Future<bool> start({
    required String roomId,
    required String userId,
    required String userName,
    required String apiKey,
  }) async {
    if (_started) return true;

    _roomId = roomId;
    _userId = userId;

    final ok = await _requestPermissions();
    if (!ok) {
      const err = 'Bluetooth: необходимо разрешение';
      debugPrint('[MeshTransport] $err');
      _errorCtrl.add(err);
      return false;
    }

    // ── Шаг 1: Initialize ────────────────────────────────────────────────────
    try {
      final masked = '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
      debugPrint('[MeshTransport] Инициализация (key: $masked)');
      await _bridgefy.initialize(
        apiKey: apiKey,
        delegate: this,
        verboseLogging: false,
      );
    } catch (e) {
      final errStr = e.toString();

      // ► После hot restart SDK отвечает "already started" на initialize() тоже.
      //   Это нормально — пропускаем initialize и идём сразу в doStart().
      if (errStr.toLowerCase().contains('already started')) {
        debugPrint('[MeshTransport] ✅ Bridgefy уже инициализирован (hot restart) — пропускаем initialize');
        // proceed to doStart() below
      } else if (errStr.contains('sessionError') ||
          errStr.contains('not equal to the previous session') ||
          errStr.contains('ID is not equal')) {
        debugPrint('[MeshTransport] ⚠️ Session mismatch при initialize, повтор через 1.2с...');
        await Future.delayed(const Duration(milliseconds: 1200));
        try {
          await _bridgefy.initialize(
            apiKey: apiKey,
            delegate: this,
            verboseLogging: false,
          );
          debugPrint('[MeshTransport] ✅ Initialize успешен после очистки сессии');
        } catch (e2) {
          final e2Str = e2.toString();
          // Retry тоже "already started" — пропускаем
          if (e2Str.toLowerCase().contains('already started')) {
            debugPrint('[MeshTransport] ✅ Bridgefy уже инициализирован после retry — продолжаем');
            // proceed to doStart() below
          } else {
            debugPrint('[MeshTransport] initialize retry error: $e2');
            _errorCtrl.add('mesh: init failed - $e2');
            return false;
          }
        }
      } else {
        debugPrint('[MeshTransport] initialize error: $e');
        _errorCtrl.add('mesh: init failed - $e');
        return false;
      }
    }

    // ── Шаг 2: Start ─────────────────────────────────────────────────────────
    _startCompleter = Completer<bool>();
    final uuid = _toUUID(userId);
    debugPrint('[MeshTransport] запуск UUID: $uuid (origin: $userId)');

    Future<bool> doStart() async {
      _startCompleter = Completer<bool>();
      try {
        await _bridgefy.start(
          userId: uuid,
          propagationProfile: BridgefyPropagationProfile.standard,
        );
      } catch (e) {
        final errStr = e.toString();

        // ► После hot restart нативный Bridgefy ещё запущен — это успех.
        //   bridgefyDidStart уже был вызван раньше или вызовется снова.
        //   Просто помечаем как запущенный и ждём callback, если нужно.
        if (errStr.toLowerCase().contains('already started')) {
          debugPrint('[MeshTransport] ✅ Bridgefy уже запущен (hot restart) — считаем успехом');
          _started = true;
          if (!(_startCompleter?.isCompleted ?? true)) {
            _startCompleter!.complete(true);
          }
          return true;
        }

        // MissingPluginException / sessionError → re-initialize + retry
        if (errStr.contains('MissingPluginException') ||
            errStr.contains('sessionError') ||
            errStr.contains('not equal to the previous session')) {
          debugPrint('[MeshTransport] ⚠️ start error ($e) — пересоздаём сессию и повторяем...');
          await Future.delayed(const Duration(milliseconds: 1500));
          try {
            await _bridgefy.initialize(
              apiKey: apiKey,
              delegate: this,
              verboseLogging: false,
            );
            _startCompleter = Completer<bool>();
            await _bridgefy.start(
              userId: uuid,
              propagationProfile: BridgefyPropagationProfile.standard,
            );
          } catch (e2) {
            final e2Str = e2.toString();
            // Retry got "already started" too — native is running, treat as success
            if (e2Str.toLowerCase().contains('already started')) {
              debugPrint('[MeshTransport] ✅ Bridgefy уже запущен после retry — считаем успехом');
              _started = true;
              if (!(_startCompleter?.isCompleted ?? true)) {
                _startCompleter!.complete(true);
              }
              return true;
            }
            debugPrint('[MeshTransport] start retry error: $e2');
            _errorCtrl.add('mesh: start failed - $e2');
            _startCompleter?.complete(false);
            return false;
          }
        } else {
          debugPrint('[MeshTransport] start error: $e');
          _errorCtrl.add('mesh: start failed - $e');
          _startCompleter?.complete(false);
          return false;
        }
      }

      final startedOk = await _startCompleter!.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          debugPrint('[MeshTransport] ⏱ таймаут 25с — ждём bridgefyDidStart через late-recovery в MeshService');
          return _started; // false при свежем старте — late-recovery в MeshService подхватит
        },
      );
      return startedOk;
    }

    return doStart();
  }


  Future<void> stop() async {
    if (!_started) return;
    try {
      await _bridgefy.stop();
    } catch (_) {}
  }

  /// Broadcasts JSON payload to all connected mesh peers.
  Future<void> broadcast(Map<String, dynamic> payload) async {
    if (!_started) {
      debugPrint('[MeshTransport] broadcast abort — SDK not started');
      return;
    }
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    try {
      await _bridgefy.send(
        data: bytes,
        transmissionMode: BridgefyTransmissionMode(
          type: BridgefyTransmissionModeType.broadcast,
          uuid: _toUUID(_roomId),
        ),
      );
    } catch (e) {
      debugPrint('[MeshTransport] broadcast error: $e');
    }
  }

  void dispose() {
    _msgCtrl.close();
    _errorCtrl.close();
  }

  // ── Bridgefy SDK callbacks ────────────────────────────────────────────────

  @override
  void bridgefyDidStart({required String currentUserID}) {
    _started = true;
    _errorCtrl.add(null);
    debugPrint('[MeshTransport] ✅ MESH запущен — пользователь: $currentUserID');
    if (!(_startCompleter?.isCompleted ?? true)) {
      _startCompleter!.complete(true);
    }
  }

  @override
  void bridgefyDidFailToStart({required BridgefyError error}) {
    final msg = error.message ?? 'Неизвестная ошибка запуска';

    // ► "already started" — нативный Bridgefy ещё работает после hot restart.
    //   Это не ошибка: считаем запуск успешным и не завершаем completer с false.
    if (msg.toLowerCase().contains('already started') ||
        msg.toLowerCase().contains('alreadystarted')) {
      debugPrint('[MeshTransport] ✅ Bridgefy уже запущен (hot restart callback) — считаем успехом');
      _started = true;
      _errorCtrl.add(null); // сбрасываем ошибку
      if (!(_startCompleter?.isCompleted ?? true)) {
        _startCompleter!.complete(true);
      }
      return; // НЕ идём дальше
    }

    _started = false;
    _errorCtrl.add(msg);
    debugPrint('[MeshTransport] ❌ Ошибка запуска: $msg');
    if (!(_startCompleter?.isCompleted ?? true)) {
      _startCompleter!.complete(false);
    }
  }

  @override
  void bridgefyDidStop() {
    _started = false;
    debugPrint('[MeshTransport] остановлен');
  }

  @override
  void bridgefyDidFailToStop({required BridgefyError error}) {
    debugPrint('[MeshTransport] ошибка остановки: ${error.message}');
  }

  @override
  void bridgefyDidDestroySession() {}

  @override
  void bridgefyDidFailToDestroySession() {}

  @override
  void bridgefyDidConnect({required String userID}) {
    debugPrint('[MeshTransport] 🔗 подключен пир: $userID');
    // Отправляем событие — MeshService отреагирует немедленным presence ping
    if (!_peerConnCtrl.isClosed) _peerConnCtrl.add(userID);
  }

  @override
  void bridgefyDidDisconnect({required String userID}) {
    debugPrint('[MeshTransport] 🔌 отключен пир: $userID');
  }

  @override
  void bridgefyDidEstablishSecureConnection({required String userID}) {
    debugPrint('[MeshTransport] 🔒 защищённое соединение: $userID');
  }

  @override
  void bridgefyDidFailToEstablishSecureConnection(
      {required String userID, required BridgefyError error}) {
    debugPrint('[MeshTransport] 🔓 ошибка защищённого соединения с $userID: ${error.message}');
  }

  @override
  void bridgefyDidSendMessage({required String messageID}) {}

  @override
  void bridgefyDidFailSendingMessage(
      {required String messageID, BridgefyError? error}) {
    debugPrint('[MeshTransport] 📤 ошибка отправки $messageID: ${error?.message}');
  }

  @override
  void bridgefyDidReceiveData({
    required Uint8List data,
    required String messageId,
    required BridgefyTransmissionMode transmissionMode,
  }) {
    try {
      final raw = utf8.decode(data);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final msgType = json['type'] as String? ?? '';

      // SOS-beacon пропускаем всегда — он должен достигать всех участников MESH без фильтра по комнате.
      // Для всех остальных типов — фильтр по roomId остаётся.
      final isBeacon = msgType == 'beacon';
      if (!isBeacon) {
        if (json['roomId'] != _roomId) {
          if (json['tripId'] != _roomId) return;
        }
      }

      // Игнорируем эхо собственных сообщений
      if (json['userId'] == _userId) return;

      // Dedup: BLE mesh передаёт пакеты по нескольким маршрутам
      final seenKey = '${json['userId']}_${json['ts']}_${json['type']}_${json['chunkIndex'] ?? 0}';
      if (_seenIds.contains(seenKey)) return;
      _seenIds.add(seenKey);
      if (_seenIds.length > _maxSeenIds) _seenIds.remove(_seenIds.first);

      final ts = json['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      // Для beacon сохраняем оригинальный tripId из пакета (tripId отправителя),
      // для остальных — наш roomId.
      final msgTripId = isBeacon
          ? (json['tripId'] as String? ?? '')
          : _roomId;
      final msg = OfflineMessage.fromJson(
        {...json, 'ts': ts, 'tripId': msgTripId},
        currentUserId: _userId,
        overrideId: 'mesh_${messageId}_$ts',
      );
      // Добавляем метаданные для определения принадлежности по комнате на уровне MeshService
      _msgCtrl.add(msg);
    } catch (e) {
      debugPrint('[MeshTransport] parse error: $e');
    }
  }

  @override
  void bridgefyDidSendDataProgress({
    required String messageID,
    required int position,
    required int of,
  }) {}

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    // On Android 12+ (API 31+) with BLUETOOTH_SCAN declared as neverForLocation,
    // location permission is NOT required for BLE mesh scanning.
    // Requesting location here alongside Geolocator causes:
    //   W/Activity: Can request only one set of permissions at a time
    // which silently blocks ALL permission grants including BLE → MESH never starts.
    // Location is Geolocator's concern; we only request BLE permissions here.
    final results = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    final scanOk    = results[Permission.bluetoothScan]?.isGranted    == true;
    final connectOk = results[Permission.bluetoothConnect]?.isGranted == true;
    final legacyOk  = results[Permission.bluetooth]?.isGranted        == true;

    debugPrint('[MeshTransport] perms: scan=$scanOk connect=$connectOk legacy=$legacyOk');
    // On Android 12+, scanOk && connectOk is sufficient.
    // On older Android, legacyOk (BLUETOOTH + BLUETOOTH_ADMIN) covers it.
    return scanOk && connectOk || legacyOk;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Deterministic UUID from MD5 hash of input string.
  String _toUUID(String input) {
    if (input.isEmpty) return '00000000-0000-0000-0000-000000000000';
    final bytes = md5.convert(utf8.encode(input)).bytes;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }
}
