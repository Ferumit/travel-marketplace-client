import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../models/offline_models.dart';
import 'mesh_transport.dart';
import 'local_profile_service.dart';
import 'sos_service.dart';
import '../env/env.dart';

/// MESH offline service — text chat + PTT voice + SOS Beacon.
///
/// Works 100% offline via Bridgefy BLE mesh.
/// Firebase Auth is used solely to resolve local user identity.
class MeshService {
  MeshService._();
  static final MeshService instance = MeshService._();

  final _auth = FirebaseAuth.instance;
  final _bt   = MeshTransport.instance;

  /// Max bytes per BLE chunk (keep below MTU budget).
  static const _chunkSize = 380;

  // ── Session state ─────────────────────────────────────────────────────────
  bool _started = false;
  String _roomId  = '';
  String _userId   = '';
  String _userName = '';

  bool _btActive = false;
  bool _btSetupDone = false; // защита от двойного вызова _setupAfterStart()
  String? _btErrorMessage;

  bool get isStarted         => _started;
  bool get isBluetoothActive => _btActive;
  String? get btErrorMessage => _btErrorMessage;
  String get currentUserId   => _userId;

  // ── PTT recording ─────────────────────────────────────────────────────────
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool get isRecording => _recording;

  // ── Presence heartbeat ────────────────────────────────────────────────────
  Timer? _presenceTimer;
  static const _presenceInterval = Duration(seconds: 10);

  // ── Beacon ──────────────────────────────────────────────────────────────────
  bool _beaconActive = false;
  Timer? _beaconTimer;
  static const _beaconInterval = Duration(minutes: 2); // Limit SOS to 1 per 2 min
  bool get isBeaconActive => _beaconActive;
  /// Стабильный signalId SOS-сессии (детерминированный UUID v5 = тот же что у relay) [BUG-2 fix]
  String? _beaconSignalId;
  /// tripId активной поездки, переданный через activateBeacon [BUG-7 fix]
  String? _beaconTripId;
  /// Точное время активации SOS (для sentAt в Firestore)
  DateTime? _beaconActivatedAt;
  /// Флаг: Firebase-запись уже сделана для этой SOS-сессии [BUG-3 fix]
  bool _sosFirebaseUploaded = false;

  // ── Incoming voice reassembly ─────────────────────────────────────────────
  final Map<String, List<_Chunk>> _incomingChunks = {};

  // ── Playback ──────────────────────────────────────────────────────────────
  final _voicePlayer = AudioPlayer();
  final _sosPlayer   = AudioPlayer();
  bool _sosAlertPlaying = false;
  StreamSubscription? _playerStateSub;

  // Chunk stale-cleanup timers
  final Map<String, Timer> _chunkExpiry = {};
  static const _chunkTtl = Duration(seconds: 60);

  // ── Busy state ────────────────────────────────────────────────────────────
  bool _isSending      = false;
  bool _isPlayingVoice = false;
  bool get isBusy         => _isSending || _isPlayingVoice;
  bool get isSending      => _isSending;
  bool get isPlayingVoice => _isPlayingVoice;

  // ── Voice history ─────────────────────────────────────────────────────────
  final List<ReceivedVoiceMessage> _voiceHistory = [];
  List<ReceivedVoiceMessage> get voiceHistory => List.unmodifiable(_voiceHistory);
  static const _maxVoiceHistory = 20;

  // ── Text chat history ─────────────────────────────────────────────────────
  final List<MeshTextMessage> _textHistory = [];
  List<MeshTextMessage> get textHistory => List.unmodifiable(_textHistory);
  static const _maxTextHistory = 100;

  // ── Peer tracking ─────────────────────────────────────────────────────────
  final Map<String, OfflinePeer> _peers = {};
  List<OfflinePeer> get nearbyPeers => List.unmodifiable(_peers.values);

  // ── Streams ───────────────────────────────────────────────────────────────
  final _eventCtrl = StreamController<MeshEvent>.broadcast();
  final _peerCtrl  = StreamController<OfflinePeer>.broadcast();

  Stream<MeshEvent>    get events     => _eventCtrl.stream;
  Stream<OfflinePeer>  get peerEvents => _peerCtrl.stream;

  StreamSubscription<OfflineMessage>? _btSub;
  StreamSubscription<String?>?        _btErrSub;
  StreamSubscription<String>?         _peerConnSub; // ping on BLE connect

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start({
    required String roomId,
    required String userId,
    required String userName,
  }) async {
    if (_started) return;

    final profile = LocalProfileService.instance;
    _roomId   = roomId.isNotEmpty   ? roomId   : 'explora-mesh';
    _userId   = userId.isNotEmpty   ? userId   : (profile.localUid.isNotEmpty   ? profile.localUid   : (_auth.currentUser?.uid ?? 'anon'));
    _userName = userName.isNotEmpty ? userName : (profile.localName.isNotEmpty  ? profile.localName  : (_auth.currentUser?.displayName ?? 'Участник'));

    _started = true;
    debugPrint('[MeshService] запущен — комната: $_roomId  пользователь: $_userName');
    _startBluetooth();
  }

  Future<void> _startBluetooth() async {
    _bt.reset();
    _btSetupDone = false; // сбрасываем защиту при каждом новом цикле запуска

    await _btErrSub?.cancel();
    _btErrSub = _bt.btError.listen((err) async {
      _btErrorMessage = err;

      // Поздний bridgefyDidStart: transport стал активен после таймаута (часто на MIUI/медленных BLE-стеках)
      if (err == null && !_btActive && _bt.isStarted) {
        debugPrint('[MeshService] 🔄 Поздний bridgefyDidStart — восстанавливаем MESH после таймаута');
        _btActive = true;
        await _setupAfterStart();
        _eventCtrl.add(MeshBtStatusEvent(true));
        return;
      }

      _eventCtrl.add(MeshBtStatusEvent(_btActive));
    });

    final ok = await _bt.start(
      roomId:   _roomId,
      userId:   _userId,
      userName: _userName,
      apiKey:   Env.bridgefyApiKey,
    );

    _btActive = ok;
    if (ok) {
      await _setupAfterStart();
    } else {
      debugPrint('[MeshService] ❌ MESH недоступен: $_btErrorMessage');
    }
    // Всегда уведомляем UI о текущем статусе BT
    _eventCtrl.add(MeshBtStatusEvent(_btActive));
  }

  /// Настраивает подписки и таймеры после того как Bridgefy успешно запустился.
  /// Вызывается как из основного пути (ok=true), так и из late-recovery (таймаут прошёл, но callback пришёл позже).
  Future<void> _setupAfterStart() async {
    // Защита от гонки: btError listener и ok=true путь могут сработать одновременно
    if (_btSetupDone) {
      debugPrint('[MeshService] ⚠️ _setupAfterStart уже вызывался — пропускаем');
      return;
    }
    _btSetupDone = true;

    await _btSub?.cancel();
    _btSub = _bt.incomingMessages.listen(_onMessage);

    await _playerStateSub?.cancel();
    _playerStateSub = _voicePlayer.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlayingVoice != playing) {
        _isPlayingVoice = playing;
        _eventCtrl.add(MeshBusyEvent(isBusy));
      }
    });

    _presenceTimer?.cancel();
    await _sendPresencePing(); // немедленный ping — в т.ч. после hot restart
    _presenceTimer = Timer.periodic(_presenceInterval, (_) => _sendPresencePing());

    await _peerConnSub?.cancel();
    _peerConnSub = _bt.peerConnected.listen((peerId) {
      debugPrint('[MeshService] 🔗 пир подключён: $peerId — шлём presence ping');
      _sendPresencePing();
    });

    debugPrint('[MeshService] ✅ MESH активен — heartbeat запущен');
  }

  /// Немедленно отправляет presence ping — вызывается при открытии экрана
  /// после hot restart, чтобы переобнаружить соседние устройства.
  Future<void> sendPresencePingNow() => _sendPresencePing();

  Future<void> stop() async {
    if (!_started) return;

    await deactivateBeacon();
    _presenceTimer?.cancel();
    _presenceTimer = null;

    if (_recording) await _recorder.stop();
    _recording = false;

    await _playerStateSub?.cancel();
    _playerStateSub = null;
    _isSending      = false;
    _isPlayingVoice = false;

    for (final t in _chunkExpiry.values) {
      t.cancel();
    }
    _chunkExpiry.clear();

    await _btSub?.cancel();
    await _btErrSub?.cancel();
    await _peerConnSub?.cancel();
    _btSub = null; _btErrSub = null; _peerConnSub = null;

    try { await _bt.stop(); } catch (_) {}
    _btActive = false;
    _btSetupDone = false;

    await _voicePlayer.stop();
    await _sosPlayer.stop();
    _sosAlertPlaying = false;

    _peers.clear();
    _incomingChunks.clear();
    _started = false;
    debugPrint('[MeshService] остановлен');
  }

  /// Broadcasts a presence packet with GPS coords so peers can display distance.
  Future<void> _sendPresencePing() async {
    if (!_btActive) return;
    double? lat, lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 4));
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}
    await _bt.broadcast({
      'type':     'presence',
      'roomId':   _roomId,
      'tripId':   _roomId, // compat
      'userId':   _userId,
      'userName': _userName,
      'lat':      lat,
      'lng':      lng,
      'ts':       DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── Text Chat ─────────────────────────────────────────────────────────────

  /// Sends a plain text message to all nearby peers via MESH.
  Future<void> sendTextMessage(String text) async {
    if (!_started || !_btActive || text.trim().isEmpty) return;

    final msgId = const Uuid().v4();
    final msg = MeshTextMessage(
      id:         msgId,
      senderId:   _userId,
      senderName: _userName,
      text:       text.trim(),
      receivedAt: DateTime.now(),
      isMine:     true,
    );

    // Add to local history immediately
    _textHistory.insert(0, msg);
    if (_textHistory.length > _maxTextHistory) _textHistory.removeLast();
    _eventCtrl.add(MeshTextHistoryUpdatedEvent(List.unmodifiable(_textHistory)));

    await _bt.broadcast({
      'type':     'text',
      'roomId':   _roomId,
      'tripId':   _roomId,
      'userId':   _userId,
      'userName': _userName,
      'text':     text.trim(),
      'msgId':    msgId,
      'ts':       DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('[MeshService] 💬 текст отправлен: "${text.trim()}"');
  }

  // ── PTT Voice ─────────────────────────────────────────────────────────────

  Future<bool> startRecording() async {
    if (!_started || !_btActive || _recording) return false;
    if (!await _recorder.hasPermission()) return false;

    final tmpDir  = await getTemporaryDirectory();
    final tmpPath = '${tmpDir.path}/mesh_ptt_${DateTime.now().millisecondsSinceEpoch}.pcm';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 8000,
        numChannels: 1,
      ),
      path: tmpPath,
    );
    _recording = true;
    debugPrint('[MeshService] 🎙 запись → $tmpPath');
    return true;
  }

  Future<void> stopRecordingAndSend() async {
    if (!_recording) return;
    _recording = false;

    final path = await _recorder.stop();
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (!file.existsSync()) return;

    final audioBytes = await file.readAsBytes();
    try { file.deleteSync(); } catch (_) {}

    if (audioBytes.isEmpty) return;
    debugPrint('[MeshService] 📤 голосовое сообщение: ${audioBytes.length} байт');
    await _sendVoiceChunks(audioBytes);
  }

  Future<void> _sendVoiceChunks(Uint8List audioBytes) async {
    final voiceMessageId = const Uuid().v4();
    final data = audioBytes.toList();
    final totalChunks = (data.length / _chunkSize).ceil().clamp(1, 9999);

    _isSending = true;
    _eventCtrl.add(MeshBusyEvent(true));

    try {
      for (int i = 0; i < totalChunks; i++) {
        final s = i * _chunkSize;
        final e = (s + _chunkSize).clamp(0, data.length);
        await _bt.broadcast({
          'type':           'voice_chunk',
          'roomId':         _roomId,
          'tripId':         _roomId,
          'userId':         _userId,
          'userName':       _userName,
          'voiceMessageId': voiceMessageId,
          'chunkIndex':     i,
          'totalChunks':    totalChunks,
          'audioChunk':     data.sublist(s, e),
          'ts':             DateTime.now().millisecondsSinceEpoch,
        });
        await Future.delayed(const Duration(milliseconds: 80));
      }
    } finally {
      _isSending = false;
      _eventCtrl.add(MeshBusyEvent(isBusy));
      debugPrint('[MeshService] ✅ $totalChunks чанков отправлено ($voiceMessageId)');
    }
  }

  // ── SOS Beacon ────────────────────────────────────────────────────────────

  /// Activates SOS beacon — broadcasts location+active to all nearby peers every 2 min.
  /// [tripId] — ID активной поездки (определяется в SOSScreen через Firestore).
  Future<void> activateBeacon({String? tripId}) async {
    if (!_started || _beaconActive) return;
    _beaconActive = true;
    _beaconActivatedAt = DateTime.now();
    _beaconTripId = tripId;
    _sosFirebaseUploaded = false;
    // BUG-2 fix: тот же алгоритм что у relay (UUID v5, детерминированный)
    _beaconSignalId = SosService.deriveSignalId(_userId, _beaconActivatedAt!);
    await _sendBeaconPing(active: true);
    _beaconTimer = Timer.periodic(_beaconInterval, (_) => _sendBeaconPing(active: true));
    _eventCtrl.add(MeshLocalBeaconEvent(true));
    debugPrint('[MeshService] 🆘 SOS beacon ВКЛ | signalId=$_beaconSignalId | tripId=$tripId');
  }

  /// Deactivates SOS beacon — notifies peers that SOS was cleared.
  Future<void> deactivateBeacon() async {
    if (!_beaconActive) return;
    _beaconActive = false;
    _beaconSignalId = null;
    _beaconTripId = null;
    _beaconActivatedAt = null;
    _sosFirebaseUploaded = false;
    _beaconTimer?.cancel();
    _beaconTimer = null;
    if (_started && _btActive) await _sendBeaconPing(active: false);
    _eventCtrl.add(MeshLocalBeaconEvent(false));
    debugPrint('[MeshService] SOS beacon ВЫКЛ');
  }

  Future<void> _sendBeaconPing({required bool active}) async {
    if (!_btActive) return;
    double? lat, lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 4));
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          lat = lastPos.latitude;
          lng = lastPos.longitude;
        }
      } catch (_) {}
    }

    await _bt.broadcast({
      'type':         'beacon',
      'roomId':       _roomId,
      // BUG-7 fix: используем реальный tripId, а не roomId
      'tripId':       _beaconTripId ?? _roomId,
      'userId':       _userId,
      'userName':     _userName,
      'beaconActive': active,
      'lat':          lat,
      'lng':          lng,
      'ts':           (_beaconActivatedAt ?? DateTime.now()).millisecondsSinceEpoch,
    });

    // BUG-3 fix: запись в Firebase только ОДИН раз за всю SOS-сессию
    if (active && _beaconSignalId != null && !_sosFirebaseUploaded) {
      _sosFirebaseUploaded = true; // сет до await, чтобы таймер не запусил ещё одну попытку
      SosService.instance.sendSos(
        signalId: _beaconSignalId!,
        senderId: _userId,
        senderName: _userName,
        // BUG-7 fix: реальный tripId из активной поездки
        tripId: _beaconTripId,
        lat: lat,
        lng: lng,
        sentAt: _beaconActivatedAt!,
      );
    }
  }

  // ── Incoming handler ──────────────────────────────────────────────────────

  void _onMessage(OfflineMessage msg) {
    _updatePeer(msg);
    switch (msg.type) {
      case OfflineMessageType.voiceChunk: _handleVoiceChunk(msg);
      case OfflineMessageType.text:       _handleTextMessage(msg);
      case OfflineMessageType.beacon:     _handleBeacon(msg);
      case OfflineMessageType.presence:   break;
      default: break;
    }
  }

  void _updatePeer(OfflineMessage msg) {
    final ex = _peers[msg.userId];
    final peer = ex?.copyWith(
      userName:        msg.userName,
      lastSeen:        msg.timestamp,
      lat:             msg.lat ?? ex.lat,
      lng:             msg.lng ?? ex.lng,
      hasLocation:     msg.lat != null || (ex.hasLocation),
      sosBroadcasting: msg.type == OfflineMessageType.beacon
          ? (msg.beaconActive ?? false) : ex.sosBroadcasting,
    ) ?? OfflinePeer(
      peerId:          msg.userId,
      userId:          msg.userId,
      userName:        msg.userName,
      lastSeen:        msg.timestamp,
      lat:             msg.lat,
      lng:             msg.lng,
      hasLocation:     msg.lat != null,
      sosBroadcasting: msg.type == OfflineMessageType.beacon && (msg.beaconActive ?? false),
    );
    _peers[msg.userId] = peer;
    _peerCtrl.add(peer);
  }

  void _handleTextMessage(OfflineMessage msg) {
    if (msg.text == null || msg.text!.isEmpty) return;
    final entry = MeshTextMessage(
      id:         msg.id,
      senderId:   msg.userId,
      senderName: msg.userName,
      text:       msg.text!,
      receivedAt: msg.timestamp,
      isMine:     false,
    );
    _textHistory.insert(0, entry);
    if (_textHistory.length > _maxTextHistory) _textHistory.removeLast();
    _eventCtrl.add(MeshTextReceivedEvent(entry));
    _eventCtrl.add(MeshTextHistoryUpdatedEvent(List.unmodifiable(_textHistory)));
    debugPrint('[MeshService] 💬 текст от ${msg.userName}: "${msg.text}"');
  }

  void _handleVoiceChunk(OfflineMessage msg) {
    final vmId  = msg.voiceMessageId;
    final idx   = msg.chunkIndex;
    final total = msg.totalChunks;
    final chunk = msg.audioChunk;
    if (vmId == null || idx == null || total == null || chunk == null || chunk.isEmpty) return;

    _incomingChunks.putIfAbsent(vmId, () => []);
    final already = _incomingChunks[vmId]!.any((c) => c.index == idx);
    if (!already) _incomingChunks[vmId]!.add(_Chunk(idx, chunk));

    _chunkExpiry[vmId]?.cancel();
    _chunkExpiry[vmId] = Timer(_chunkTtl, () {
      _incomingChunks.remove(vmId);
      _chunkExpiry.remove(vmId);
    });

    final received = _incomingChunks[vmId]!.length;
    if (received >= total) {
      _chunkExpiry.remove(vmId)?.cancel();
      final assembled = (_incomingChunks.remove(vmId)!
        ..sort((a, b) => a.index.compareTo(b.index)))
          .expand((c) => c.data).toList();
      _playPcm(Uint8List.fromList(assembled), msg.userName);
    }
  }

  Future<void> _playPcm(Uint8List pcmBytes, String senderName) async {
    try {
      final wavBytes = _buildWav(pcmBytes, sampleRate: 8000, channels: 1, bitsPerSample: 16);
      final tmpDir   = await getTemporaryDirectory();
      final timestamp = DateTime.now();
      final tmpPath = '${tmpDir.path}/mesh_rx_${timestamp.millisecondsSinceEpoch}.wav';
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(wavBytes);

      final entry = ReceivedVoiceMessage(
        id:         tmpPath,
        senderName: senderName,
        wavPath:    tmpPath,
        receivedAt: timestamp,
        durationSec: (pcmBytes.length / (8000 * 2)).round(),
      );
      _voiceHistory.insert(0, entry);
      if (_voiceHistory.length > _maxVoiceHistory) _voiceHistory.removeLast();
      _eventCtrl.add(MeshVoiceHistoryUpdatedEvent(List.unmodifiable(_voiceHistory)));

      await _voicePlayer.stop();
      await _voicePlayer.play(DeviceFileSource(tmpPath));
      _eventCtrl.add(MeshVoiceReceivedEvent(senderName));
    } catch (e, stack) {
      debugPrint('[MeshService] ❌ ошибка воспроизведения: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'MeshService._playPcm', fatal: false);
    }
  }

  Future<void> replayMessage(ReceivedVoiceMessage msg) async {
    final file = File(msg.wavPath);
    if (!file.existsSync()) return;
    await _voicePlayer.stop();
    await _voicePlayer.play(DeviceFileSource(msg.wavPath));
  }

  static Uint8List _buildWav(
    Uint8List pcm, {
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate   = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataLen    = pcm.length;
    final totalLen   = 36 + dataLen;

    final header = ByteData(44);
    header.setUint32(0,  0x52494646, Endian.big);
    header.setUint32(4,  totalLen,   Endian.little);
    header.setUint32(8,  0x57415645, Endian.big);
    header.setUint32(12, 0x666d7420, Endian.big);
    header.setUint32(16, 16,         Endian.little);
    header.setUint16(20, 1,          Endian.little);
    header.setUint16(22, channels,   Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate,   Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    header.setUint32(36, 0x64617461, Endian.big);
    header.setUint32(40, dataLen,    Endian.little);

    final out = Uint8List(44 + dataLen);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, 44 + dataLen, pcm);
    return out;
  }

  void _handleBeacon(OfflineMessage msg) {
    final active = msg.beaconActive ?? false;
    debugPrint('[MeshService] beacon от ${msg.userName}: active=$active | tripId=${msg.tripId}');
    if (active) {
      // Relay: передаём сигнал в Firebase если есть интернет
      SosService.instance.relayReceivedSos(
        msg: msg,
        relayUserId: _userId,
      );
      if (!_sosAlertPlaying) {
        _sosAlertPlaying = true;
        _sosPlayer.setReleaseMode(ReleaseMode.loop);
        _sosPlayer.play(AssetSource('sounds/sos_alert.mp3')).catchError((e) {
          debugPrint('[MeshService] ⚠️ SOS аудио недоступно: $e');
          _sosAlertPlaying = false;
        });
      }
      // Приоритет: проверяем, является ли отправитель участником нашего маршрута (tripId совпадает)
      final isFromMyTrip = msg.tripId.isNotEmpty && msg.tripId == _roomId;
      _eventCtrl.add(MeshSosReceivedEvent(
        userId: msg.userId,
        userName: msg.userName,
        lat: msg.lat,
        lng: msg.lng,
        isFromMyTrip: isFromMyTrip,
      ));
    } else {
      if (_sosAlertPlaying) {
        _sosAlertPlaying = false;
        _sosPlayer.stop();
      }
      _eventCtrl.add(MeshSosClearedEvent(msg.userId));
    }
  }

  Future<void> dismissSosAlert() async {
    _sosAlertPlaying = false;
    await _sosPlayer.stop();
  }

  // ── Distance helpers ──────────────────────────────────────────────────────

  /// Haversine distance in meters between two coordinate pairs.
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1), dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double d) => d * pi / 180;

  /// Distance to a specific peer, or null if either location is unknown.
  double? distanceToPeer(String peerId, {double? myLat, double? myLng}) {
    final peer = _peers[peerId];
    if (peer == null || !peer.hasLocation) return null;
    if (myLat == null || myLng == null) return null;
    return distanceMeters(myLat, myLng, peer.lat!, peer.lng!);
  }

  static String formatDistance(double m) =>
      m < 1000 ? '~${m.round()} м' : '~${(m / 1000).toStringAsFixed(1)} км';

  void dispose() {
    _playerStateSub?.cancel();
    for (final t in _chunkExpiry.values) {
      t.cancel();
    }
    _btSub?.cancel(); _btErrSub?.cancel();
    _eventCtrl.close(); _peerCtrl.close();
    _voicePlayer.dispose(); _sosPlayer.dispose();
    _bt.dispose();
  }
}

class _Chunk {
  final int index; final List<int> data;
  const _Chunk(this.index, this.data);
}

// ── MeshEvent hierarchy ───────────────────────────────────────────────────────

abstract class MeshEvent { const MeshEvent(); }

class MeshBtStatusEvent extends MeshEvent {
  final bool active;
  const MeshBtStatusEvent(this.active);
}

class MeshVoiceReceivedEvent extends MeshEvent {
  final String userName;
  const MeshVoiceReceivedEvent(this.userName);
}

class MeshTextReceivedEvent extends MeshEvent {
  final MeshTextMessage message;
  const MeshTextReceivedEvent(this.message);
}

class MeshSosReceivedEvent extends MeshEvent {
  final String userId, userName;
  final double? lat, lng;
  /// true = SOS-отправитель участник нашего маршрута (приоритетное уведомление).
  /// false = посторонний пользователь MESH — менее интрузивное уведомление.
  final bool isFromMyTrip;
  const MeshSosReceivedEvent({
    required this.userId,
    required this.userName,
    this.lat,
    this.lng,
    this.isFromMyTrip = false,
  });
}

class MeshSosClearedEvent extends MeshEvent {
  final String userId;
  const MeshSosClearedEvent(this.userId);
}

class MeshLocalBeaconEvent extends MeshEvent {
  final bool active;
  const MeshLocalBeaconEvent(this.active);
}

class MeshBusyEvent extends MeshEvent {
  final bool busy;
  const MeshBusyEvent(this.busy);
}

class MeshVoiceHistoryUpdatedEvent extends MeshEvent {
  final List<ReceivedVoiceMessage> history;
  const MeshVoiceHistoryUpdatedEvent(this.history);
}

class MeshTextHistoryUpdatedEvent extends MeshEvent {
  final List<MeshTextMessage> history;
  const MeshTextHistoryUpdatedEvent(this.history);
}

// ── ReceivedVoiceMessage ──────────────────────────────────────────────────────

class ReceivedVoiceMessage {
  final String id;
  final String senderName;
  final String wavPath;
  final DateTime receivedAt;
  final int durationSec;

  const ReceivedVoiceMessage({
    required this.id,
    required this.senderName,
    required this.wavPath,
    required this.receivedAt,
    this.durationSec = 0,
  });
}
