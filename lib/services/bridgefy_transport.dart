import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:bridgefy/bridgefy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

import '../models/offline_models.dart';

/// Bridgefy transport for WAVE offline mesh.
///
/// Key design decisions:
/// - Singleton with explicit [reset] so it can be reused across sessions.
/// - [start] awaits the async [bridgefyDidStart] callback via a Completer
///   before returning, eliminating the race condition where callers believe
///   BT is active before the SDK confirms it.
/// - [broadcast] only fires when SDK is truly started (not just initialised).
class BridgefyTransport with BridgefyDelegate {
  BridgefyTransport._();
  static final BridgefyTransport instance = BridgefyTransport._();

  final _bridgefy = Bridgefy();

  final _msgCtrl   = StreamController<OfflineMessage>.broadcast();
  final _errorCtrl = StreamController<String?>.broadcast();

  bool _started = false;
  String _tripId = '';
  String _userId = '';

  // Message dedup — BLE mesh retransmits packets via multiple paths
  final Set<String> _seenIds = {};
  static const _maxSeenIds = 200;

  // Completer resolves once bridgefyDidStart fires (or fails).
  Completer<bool>? _startCompleter;

  bool get isStarted => _started;

  Stream<OfflineMessage> get incomingMessages => _msgCtrl.stream;
  Stream<String?> get btError => _errorCtrl.stream;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Resets the singleton so it can be cleanly restarted.
  void reset() {
    _started = false;
    _tripId = '';
    _userId = '';
    _startCompleter = null;
  }

  Future<bool> start({
    required String tripId,
    required String userId,
    required String userName,
    required String apiKey,
  }) async {
    if (_started) return true;

    _tripId = tripId;
    _userId = userId;

    // ── Request permissions ──────────────────────────────────────────────────
    final ok = await _requestPermissions();
    if (!ok) {
      const err = 'Bluetooth: permissions missing';
      debugPrint('[BridgefyTransport] $err');
      _errorCtrl.add(err);
      return false;
    }

    // ── Initialize SDK ───────────────────────────────────────────────────────
    try {
      final masked = '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
      debugPrint('[BridgefyTransport] Initializing (key: $masked, ${apiKey.length} chars)');
      await _bridgefy.initialize(
        apiKey: apiKey,
        delegate: this,
        verboseLogging: false, // verbose SDK logs flood the console with per-packet noise
      );
    } catch (e, stack) {
      debugPrint('[BridgefyTransport] initialize error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'BridgefyTransport.initialize', fatal: false);
      _errorCtrl.add('bridgefy: init failed - $e');
      return false;
    }

    // ── Start SDK — wait for async callback ──────────────────────────────────
    _startCompleter = Completer<bool>();
    try {
      final uuid = _toUUID(userId);
      debugPrint('[BridgefyTransport] starting for UUID: $uuid (origin: $userId)');
      await _bridgefy.start(
        userId: uuid,
        propagationProfile: BridgefyPropagationProfile.standard,
      );
    } catch (e, stack) {
      debugPrint('[BridgefyTransport] start error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'BridgefyTransport.start', fatal: false);
      _errorCtrl.add('bridgefy: start failed - $e');
      _startCompleter?.complete(false);
      return false;
    }

    // Wait up to 10 s for bridgefyDidStart / bridgefyDidFailToStart
    final startedOk = await _startCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[BridgefyTransport] ⏱ start timed out — will still try');
        return _started; // use whatever status we have
      },
    );

    return startedOk;
  }

  Future<void> stop() async {
    if (!_started) return;
    try {
      await _bridgefy.stop();
    } catch (_) {}
    // _started is flipped in bridgefyDidStop callback
  }

  /// Broadcasts JSON payload to the mesh network.
  Future<void> broadcast(Map<String, dynamic> payload) async {
    if (!_started) {
      debugPrint('[BridgefyTransport] broadcast aborted — SDK not started yet');
      return;
    }
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    try {
      await _bridgefy.send(
        data: bytes,
        transmissionMode: BridgefyTransmissionMode(
          type: BridgefyTransmissionModeType.broadcast,
          uuid: _toUUID(_tripId),
        ),
      );
    } catch (e, stack) {
      debugPrint('[BridgefyTransport] broadcast error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'BridgefyTransport.broadcast', fatal: false);
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
    _errorCtrl.add(null); // null = no error
    debugPrint('[BridgefyTransport] ✅ started — SDK user: $currentUserID');
    if (!(_startCompleter?.isCompleted ?? true)) {
      _startCompleter!.complete(true);
    }
  }

  @override
  void bridgefyDidFailToStart({required BridgefyError error}) {
    _started = false;
    final msg = error.message ?? 'Unknown startup error';
    _errorCtrl.add(msg);
    debugPrint('[BridgefyTransport] ❌ failed to start: $msg');
    if (!(_startCompleter?.isCompleted ?? true)) {
      _startCompleter!.complete(false);
    }
  }

  @override
  void bridgefyDidStop() {
    _started = false;
    debugPrint('[BridgefyTransport] stopped');
  }

  @override
  void bridgefyDidFailToStop({required BridgefyError error}) {
    debugPrint('[BridgefyTransport] failed to stop: ${error.message}');
  }

  @override
  void bridgefyDidDestroySession() {}

  @override
  void bridgefyDidFailToDestroySession() {}

  @override
  void bridgefyDidConnect({required String userID}) {
    debugPrint('[BridgefyTransport] 🔗 connected to peer: $userID');
  }

  @override
  void bridgefyDidDisconnect({required String userID}) {
    debugPrint('[BridgefyTransport] 🔌 disconnected from peer: $userID');
  }

  @override
  void bridgefyDidEstablishSecureConnection({required String userID}) {
    debugPrint('[BridgefyTransport] 🔒 secure connection with: $userID');
  }

  @override
  void bridgefyDidFailToEstablishSecureConnection(
      {required String userID, required BridgefyError error}) {
    debugPrint('[BridgefyTransport] 🔓 secure connection failed with $userID: ${error.message}');
  }

  @override
  void bridgefyDidSendMessage({required String messageID}) {
    // Not logged — fires for every chunk and floods the console.
  }

  @override
  void bridgefyDidFailSendingMessage(
      {required String messageID, BridgefyError? error}) {
    debugPrint('[BridgefyTransport] 📤 failed to send $messageID: ${error?.message}');
  }

  @override
  void bridgefyDidReceiveData({
    required Uint8List data,
    required String messageId,
    required BridgefyTransmissionMode transmissionMode,
  }) {
    debugPrint('[BridgefyTransport] 📩 received ${data.length}b (mode: ${transmissionMode.type})');
    try {
      final raw = utf8.decode(data);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Filter out messages not belonging to our trip room
      if (json['tripId'] != _tripId) {
        debugPrint('[BridgefyTransport] ⚠ ignored — tripId mismatch: "${json['tripId']}" != "$_tripId"');
        return;
      }

      // Ignore our own echoed messages (Bridgefy broadcast echoes to sender)
      if (json['userId'] == _userId) {
        return; // own-echo: silent drop
      }

      // Dedup: BLE mesh retransmits same packet on multiple paths — skip seen IDs
      final seenKey = '${json['userId']}_${json['ts']}_${json['type']}_${json['chunkIndex'] ?? 0}';
      if (_seenIds.contains(seenKey)) return; // already processed
      _seenIds.add(seenKey);
      if (_seenIds.length > _maxSeenIds) _seenIds.remove(_seenIds.first);

      final ts  = json['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final msg = OfflineMessage.fromJson(
        {...json, 'ts': ts},
        currentUserId: _userId,
        overrideId: 'bridgefy_${messageId}_$ts',
      );
      debugPrint('[BridgefyTransport] ✅ dispatching type=${json['type']} from userId=${json['userId']}');
      _msgCtrl.add(msg);
    } catch (e, stack) {
      debugPrint('[BridgefyTransport] parse error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'BridgefyTransport.bridgefyDidReceiveData', fatal: false);
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
    final results = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    final locOk     = results[Permission.location]?.isGranted        == true;
    final scanOk    = results[Permission.bluetoothScan]?.isGranted    == true;
    final connectOk = results[Permission.bluetoothConnect]?.isGranted == true;
    final legacyOk  = results[Permission.bluetooth]?.isGranted        == true;

    debugPrint('[BridgefyTransport] perms — loc=$locOk scan=$scanOk connect=$connectOk legacy=$legacyOk');

    return locOk && (scanOk && connectOk || legacyOk);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _toUUID(String input) {
    if (input.isEmpty) return '00000000-0000-0000-0000-000000000000';
    // Deterministic UUID from MD5 hash
    final bytes = md5.convert(utf8.encode(input)).bytes;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }
}
