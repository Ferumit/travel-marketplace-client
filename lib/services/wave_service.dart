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
import 'bridgefy_transport.dart';
import 'local_profile_service.dart';
import '../env/env.dart';

/// WAVE mesh service — PTT voice memos + SOS Beacon.
///
/// No Firestore. All data flows exclusively over Bridgefy BLE mesh.
/// Firebase Auth is used solely to resolve user identity.
class WaveService {
  WaveService._();
  static final WaveService instance = WaveService._();

  final _auth = FirebaseAuth.instance;
  final _bt   = BridgefyTransport.instance;

  /// Max bytes per BLE chunk (keep below MTU budget).
  static const _chunkSize = 380;

  // ── Session state ─────────────────────────────────────────────────────────
  bool _started = false;
  String _tripId = '';
  String _userId = '';
  String _userName = '';

  bool _btActive = false;
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
  // Sends a tiny 'presence' packet every 10 s so peers can detect each other.
  Timer? _presenceTimer;
  static const _presenceInterval = Duration(seconds: 10);

  // ── Beacon ────────────────────────────────────────────────────────────────
  // SOS beacon is triggered from SOSScreen and kept alive by a timer.
  // WaveService broadcasts location+active flag; receivers play an alert.
  bool _beaconActive = false;
  Timer? _beaconTimer;
  static const _beaconInterval = Duration(minutes: 2); // Limit SOS to 1 per 2 min
  bool get isBeaconActive => _beaconActive;

  // ── Incoming voice reassembly ─────────────────────────────────────────────
  final Map<String, List<_Chunk>> _incomingChunks = {};

  // ── Playback ──────────────────────────────────────────────────────────────
  final _voicePlayer = AudioPlayer();
  final _sosPlayer   = AudioPlayer();
  bool _sosAlertPlaying = false;
  StreamSubscription? _playerStateSub; // C1 fix: cancel on stop/restart

  // Chunk stale-cleanup timers (M2 fix)
  final Map<String, Timer> _chunkExpiry = {};
  static const _chunkTtl = Duration(seconds: 60);

  // ── Busy state (sending chunks or playing received audio) ─────────────────────
  bool _isSending      = false;
  bool _isPlayingVoice = false;
  bool get isBusy         => _isSending || _isPlayingVoice;
  bool get isSending      => _isSending;
  bool get isPlayingVoice => _isPlayingVoice;

  // ── Voice message history (received & replayable) ───────────────────────
  final List<ReceivedVoiceMessage> _voiceHistory = [];
  List<ReceivedVoiceMessage> get voiceHistory => List.unmodifiable(_voiceHistory);
  static const _maxHistory = 20;

  // ── Peer tracking ─────────────────────────────────────────────────────────
  final Map<String, OfflinePeer> _peers = {};
  List<OfflinePeer> get nearbyPeers => List.unmodifiable(_peers.values);

  // ── Streams ───────────────────────────────────────────────────────────────
  final _eventCtrl = StreamController<WaveEvent>.broadcast();
  final _peerCtrl  = StreamController<OfflinePeer>.broadcast();

  Stream<WaveEvent>   get events     => _eventCtrl.stream;
  Stream<OfflinePeer> get peerEvents => _peerCtrl.stream;

  StreamSubscription<OfflineMessage>? _btSub;
  StreamSubscription<String?>?        _btErrSub;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start({
    required String tripId,
    required String userId,
    required String userName,
  }) async {
    if (_started) return;

    final profile = LocalProfileService.instance;
    // Use 'wave-mesh' as universal default so all devices share the same BLE room
    _tripId   = tripId.isNotEmpty   ? tripId   : 'wave-mesh';
    _userId   = userId.isNotEmpty   ? userId   : (profile.localUid.isNotEmpty   ? profile.localUid   : (_auth.currentUser?.uid ?? 'anon'));
    _userName = userName.isNotEmpty ? userName : (profile.localName.isNotEmpty  ? profile.localName  : (_auth.currentUser?.displayName ?? 'Турист'));

    _started = true;
    debugPrint('[WaveService] started – room: $_tripId  user: $_userName');
    _startBluetooth();
  }

  Future<void> _startBluetooth() async {
    _bt.reset();

    await _btErrSub?.cancel();
    _btErrSub = _bt.btError.listen((err) {
      _btErrorMessage = err;
      _eventCtrl.add(WaveBtStatusEvent(_btActive));
    });

    final ok = await _bt.start(
      tripId:   _tripId,
      userId:   _userId,
      userName: _userName,
      apiKey:   Env.bridgefyApiKey,
    );

    _btActive = ok;
    if (ok) {
      await _btSub?.cancel();
      _btSub = _bt.incomingMessages.listen(_onMessage);

      // C1 fix: cancel any previous player state subscription before adding a new one
      await _playerStateSub?.cancel();
      _playerStateSub = _voicePlayer.onPlayerStateChanged.listen((state) {
        final playing = state == PlayerState.playing;
        if (_isPlayingVoice != playing) {
          _isPlayingVoice = playing;
          _eventCtrl.add(WaveBusyEvent(isBusy));
        }
      });

      // Cancel previous presence timer to prevent multiple timers accumulating
      _presenceTimer?.cancel();
      _presenceTimer = null;

      // Send an immediate ping so nearby peers see us right away,
      // then keep pinging periodically.
      await _sendPresencePing();
      _presenceTimer = Timer.periodic(_presenceInterval, (_) => _sendPresencePing());
      debugPrint('[WaveService] ✅ Bridgefy active — presence heartbeat started');
    } else {
      debugPrint('[WaveService] ❌ Bridgefy unavailable: $_btErrorMessage');
    }
    _eventCtrl.add(WaveBtStatusEvent(_btActive));
  }

  Future<void> stop() async {
    if (!_started) return;

    await deactivateBeacon(); // send "SOS off" before stopping
    _presenceTimer?.cancel();
    _presenceTimer = null;

    if (_recording) await _recorder.stop();
    _recording = false;

    // C1+M3 fix: cancel player sub and reset busy flags
    await _playerStateSub?.cancel();
    _playerStateSub = null;
    _isSending      = false;
    _isPlayingVoice = false;

    // M2 fix: cancel all stale-chunk timers
    for (final t in _chunkExpiry.values) {
      t.cancel();
    }
    _chunkExpiry.clear();

    await _btSub?.cancel();
    await _btErrSub?.cancel();
    _btSub = null; _btErrSub = null;

    try { await _bt.stop(); } catch (_) {}
    _btActive = false;

    await _voicePlayer.stop();
    await _sosPlayer.stop();
    _sosAlertPlaying = false;

    _peers.clear();
    _incomingChunks.clear();
    _started = false;
    debugPrint('[WaveService] stopped');
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
    } catch (_) {} // location unavailable — send ping anyway
    await _bt.broadcast({
      'type':     'presence',
      'tripId':   _tripId,
      'userId':   _userId,
      'userName': _userName,
      'lat': ?lat,
      'lng': ?lng,
      'ts':       DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── PTT Voice ─────────────────────────────────────────────────────────────

  Future<bool> startRecording() async {
    if (!_started || !_btActive || _recording) return false;
    if (!await _recorder.hasPermission()) return false;

    // Use path_provider so the temp directory is valid on Android
    final tmpDir  = await getTemporaryDirectory();
    final tmpPath = '${tmpDir.path}/wave_ptt_${DateTime.now().millisecondsSinceEpoch}.pcm';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 8000,
        numChannels: 1,
      ),
      path: tmpPath,
    );
    _recording = true;
    debugPrint('[WaveService] 🎙 recording → $tmpPath');
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
    debugPrint('[WaveService] 📤 voice memo: ${audioBytes.length} bytes');
    await _sendVoiceChunks(audioBytes);
  }

  Future<void> _sendVoiceChunks(Uint8List audioBytes) async {
    final voiceMessageId = const Uuid().v4();
    final data = audioBytes.toList();
    final totalChunks = (data.length / _chunkSize).ceil().clamp(1, 9999);
    debugPrint('[WaveService] 📤 sending $totalChunks chunks (${audioBytes.length} bytes, id: $voiceMessageId)');

    _isSending = true;
    _eventCtrl.add(WaveBusyEvent(true));

    try {
      for (int i = 0; i < totalChunks; i++) {
        final s = i * _chunkSize;
        final e = (s + _chunkSize).clamp(0, data.length);
        await _bt.broadcast({
          'type':           'voice_chunk',
          'tripId':         _tripId,
          'userId':         _userId,
          'userName':       _userName,
          'voiceMessageId': voiceMessageId,
          'chunkIndex':     i,
          'totalChunks':    totalChunks,
          'audioChunk':     data.sublist(s, e),
          'ts':             DateTime.now().millisecondsSinceEpoch,
        });
        // Small delay to avoid flooding the BLE stack
        await Future.delayed(const Duration(milliseconds: 80));
      }
    } finally {
      _isSending = false;
      _eventCtrl.add(WaveBusyEvent(isBusy));
      debugPrint('[WaveService] ✅ all $totalChunks chunks sent ($voiceMessageId)');
    }
  }

  // ── SOS Beacon (called by SOSScreen) ────────────────────────────────

  /// Starts the SOS beacon. Immediately broadcasts location + repeats every 5 s.
  /// Safe to call multiple times — no-op if already active.
  Future<void> activateBeacon() async {
    if (!_started || _beaconActive) return;
    _beaconActive = true;
    await _sendBeaconPing(active: true);
    _beaconTimer = Timer.periodic(_beaconInterval, (_) => _sendBeaconPing(active: true));
    _eventCtrl.add(WaveLocalBeaconEvent(true));
    debugPrint('[WaveService] 🆘 SOS beacon ON');
  }

  /// Stops the SOS beacon and notifies peers that it was deactivated.
  Future<void> deactivateBeacon() async {
    if (!_beaconActive) return;
    _beaconActive = false;
    _beaconTimer?.cancel();
    _beaconTimer = null;
    if (_started && _btActive) await _sendBeaconPing(active: false);
    _eventCtrl.add(WaveLocalBeaconEvent(false));
    debugPrint('[WaveService] SOS beacon OFF');
  }

  Future<void> _sendBeaconPing({required bool active}) async {
    if (!_btActive) return;
    // Try to get location; if unavailable, still send the beacon (without coords)
    double? lat, lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 5));
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    await _bt.broadcast({
      'type':         'beacon',
      'tripId':       _tripId,
      'userId':       _userId,
      'userName':     _userName,
      'beaconActive': active,
      'lat': ?lat,
      'lng': ?lng,
      'ts':           DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── Incoming handler ──────────────────────────────────────────────────────

  void _onMessage(OfflineMessage msg) {
    _updatePeer(msg);
    switch (msg.type) {
      case OfflineMessageType.voiceChunk: _handleVoiceChunk(msg);
      case OfflineMessageType.beacon:     _handleBeacon(msg);
      case OfflineMessageType.presence:   break; // peer tracking already done by _updatePeer
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

  void _handleVoiceChunk(OfflineMessage msg) {
    final vmId  = msg.voiceMessageId;
    final idx   = msg.chunkIndex;
    final total = msg.totalChunks;
    final chunk = msg.audioChunk;
    if (vmId == null || idx == null || total == null || chunk == null || chunk.isEmpty) return;

    _incomingChunks.putIfAbsent(vmId, () => []);
    // Guard against duplicate chunks (BLE mesh can repeat packets)
    final already = _incomingChunks[vmId]!.any((c) => c.index == idx);
    if (!already) _incomingChunks[vmId]!.add(_Chunk(idx, chunk));

    // M2 fix: reset stale-cleanup timer each time a chunk arrives
    _chunkExpiry[vmId]?.cancel();
    _chunkExpiry[vmId] = Timer(_chunkTtl, () {
      _incomingChunks.remove(vmId);
      _chunkExpiry.remove(vmId);
      debugPrint('[WaveService] 🗑 stale chunks for $vmId evicted');
    });

    final received = _incomingChunks[vmId]!.length;
    if (received == 1 || received == total) {
      debugPrint('[WaveService] 🔊 chunks: $received/$total from ${msg.userName}');
    }

    if (received >= total) {
      _chunkExpiry.remove(vmId)?.cancel(); // disarm expiry — message is complete
      final assembled = (_incomingChunks.remove(vmId)!
        ..sort((a, b) => a.index.compareTo(b.index)))
          .expand((c) => c.data).toList();
      debugPrint('[WaveService] 🎧 assembled ${assembled.length} bytes from ${msg.userName}');
      // C2 fix: use unawaited so calling code stays sync, but track play queue via _isPlayingVoice
      _playPcm(Uint8List.fromList(assembled), msg.userName);
    }
  }

  /// Wraps raw 8000 Hz mono 16-bit PCM in a WAV container, plays it,
  /// and adds it to [voiceHistory] for later replay.
  Future<void> _playPcm(Uint8List pcmBytes, String senderName) async {
    try {
      final wavBytes = _buildWav(pcmBytes, sampleRate: 8000, channels: 1, bitsPerSample: 16);
      final tmpDir   = await getTemporaryDirectory();
      // Use a stable name based on timestamp so we can replay later
      final timestamp = DateTime.now();
      final tmpPath = '${tmpDir.path}/wave_rx_${timestamp.millisecondsSinceEpoch}.wav';
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(wavBytes);
      debugPrint('[WaveService] 💾 WAV written → $tmpPath (${wavBytes.length} b)');

      // Add to history BEFORE playing so the UI can show it immediately
      final entry = ReceivedVoiceMessage(
        id:         tmpPath,
        senderName: senderName,
        wavPath:    tmpPath,
        receivedAt: timestamp,
        durationSec: (pcmBytes.length / (8000 * 2)).round(),
      );
      _voiceHistory.insert(0, entry);
      if (_voiceHistory.length > _maxHistory) _voiceHistory.removeLast();
      _eventCtrl.add(WaveVoiceHistoryUpdatedEvent(List.unmodifiable(_voiceHistory)));

      await _voicePlayer.stop();
      await _voicePlayer.play(DeviceFileSource(tmpPath));

      _eventCtrl.add(WaveVoiceReceivedEvent(senderName));
    } catch (e, stack) {
      debugPrint('[WaveService] ❌ playback error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'WaveService._playPcm', fatal: false);
    }
  }

  /// Replays a previously received voice message from [voiceHistory].
  Future<void> replayMessage(ReceivedVoiceMessage msg) async {
    final file = File(msg.wavPath);
    if (!file.existsSync()) {
      debugPrint('[WaveService] replay: file not found ${msg.wavPath}');
      return;
    }
    await _voicePlayer.stop();
    await _voicePlayer.play(DeviceFileSource(msg.wavPath));
  }

  /// Builds a minimal 44-byte WAV header followed by raw PCM data.
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
    // RIFF chunk
    header.setUint32(0,  0x52494646, Endian.big);  // 'RIFF'
    header.setUint32(4,  totalLen,   Endian.little);
    header.setUint32(8,  0x57415645, Endian.big);  // 'WAVE'
    // fmt sub-chunk
    header.setUint32(12, 0x666d7420, Endian.big);  // 'fmt '
    header.setUint32(16, 16,         Endian.little); // subchunk size
    header.setUint16(20, 1,          Endian.little); // PCM
    header.setUint16(22, channels,   Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate,   Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    header.setUint32(36, 0x64617461, Endian.big);  // 'data'
    header.setUint32(40, dataLen,    Endian.little);

    final out = Uint8List(44 + dataLen);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, 44 + dataLen, pcm);
    return out;
  }

  void _handleBeacon(OfflineMessage msg) {
    final active = msg.beaconActive ?? false;
    debugPrint('[WaveService] beacon from ${msg.userName}: active=$active');
    if (active) {
      if (!_sosAlertPlaying) {
        _sosAlertPlaying = true;
        _sosPlayer.setReleaseMode(ReleaseMode.loop);
        _sosPlayer.play(AssetSource('sounds/sos_alert.mp3'));
      }
      _eventCtrl.add(WaveSosReceivedEvent(
        userId: msg.userId, userName: msg.userName, lat: msg.lat, lng: msg.lng,
      ));
    } else {
      if (_sosAlertPlaying) {
        _sosAlertPlaying = false;
        _sosPlayer.stop();
      }
      _eventCtrl.add(WaveSosClearedEvent(msg.userId));
    }
  }

  Future<void> dismissSosAlert() async {
    _sosAlertPlaying = false;
    await _sosPlayer.stop();
  }

  // ── Distance (Haversine) ──────────────────────────────────────────────────

  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1), dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
  static double _rad(double d) => d * pi / 180;

  static String formatDistance(double m) =>
      m < 1000 ? '${m.round()} м' : '${(m / 1000).toStringAsFixed(1)} км';

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

// ── WaveEvent hierarchy ───────────────────────────────────────────────────────

abstract class WaveEvent { const WaveEvent(); }

class WaveBtStatusEvent extends WaveEvent {
  final bool active;
  const WaveBtStatusEvent(this.active);
}

class WaveVoiceReceivedEvent extends WaveEvent {
  final String userName;
  const WaveVoiceReceivedEvent(this.userName);
}

class WaveSosReceivedEvent extends WaveEvent {
  final String userId, userName;
  final double? lat, lng;
  const WaveSosReceivedEvent({required this.userId, required this.userName, this.lat, this.lng});
}

class WaveSosClearedEvent extends WaveEvent {
  final String userId;
  const WaveSosClearedEvent(this.userId);
}

class WaveLocalBeaconEvent extends WaveEvent {
  final bool active;
  const WaveLocalBeaconEvent(this.active);
}

/// Fired when the busy state changes (sending chunks or playing audio).
/// Screen listens to this to enable/disable navigation via PopScope.
class WaveBusyEvent extends WaveEvent {
  final bool busy;
  const WaveBusyEvent(this.busy);
}

/// Fired when the voice message history is updated (new message received).
class WaveVoiceHistoryUpdatedEvent extends WaveEvent {
  final List<ReceivedVoiceMessage> history;
  const WaveVoiceHistoryUpdatedEvent(this.history);
}

// ── ReceivedVoiceMessage (voice history entry) ────────────────────────────────

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
