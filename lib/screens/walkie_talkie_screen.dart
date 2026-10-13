import '../theme/app_colors.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/wave_service.dart';
import '../services/local_profile_service.dart';
import '../theme/theme.dart';
import '../models/offline_models.dart';

/// WAVE screen — Bridgefy BLE mesh PTT walkie-talkie.
///
/// Tabs:
///   1. 🎙 Voice  — voice history + Zello-like PTT button
///   2. 👥 Participants — nearby peers with distance
class WalkieTalkieScreen extends StatefulWidget {
  final String tripId;
  final String userId;
  final String userName;

  const WalkieTalkieScreen({
    super.key,
    this.tripId = '',
    this.userId = '',
    this.userName = '',
  });

  @override
  State<WalkieTalkieScreen> createState() => _WalkieTalkieScreenState();
}

class _WalkieTalkieScreenState extends State<WalkieTalkieScreen>
    with TickerProviderStateMixin {

  late final TabController _tabCtrl;
  final _wave = WaveService.instance;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isStarted   = false;
  bool _isRecording = false;
  bool _btActive    = false;
  bool _isBusy      = false;
  bool _lockPtt     = false;  // Zello lock mode: swipe-up to lock recording
  String? _liveTransmitter; // name of peer currently transmitting

  /// Voice message history (newest first).
  List<ReceivedVoiceMessage> _history = [];

  /// Nearby peers.
  final List<OfflinePeer> _peers = [];

  double? _myLat, _myLng;

  StreamSubscription<WaveEvent>?   _eventSub;
  StreamSubscription<OfflinePeer>? _peerSub;

  late final AnimationController _pulseCtrl;
  late final Animation<double>    _pulseAnim;
  late final AnimationController _pttCtrl;  // expands when recording
  late final Animation<double>    _pttAnim;

  bool _initialized = false;

  // PTT drag-lock detection
  static const _lockThreshold = -60.0; // drag-up distance in logical pixels

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _pttCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _pttAnim = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _pttCtrl, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _start();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _pttCtrl.dispose();
    _eventSub?.cancel();
    _peerSub?.cancel();
    _wave.stop();
    super.dispose();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> _start() async {
    if (!mounted) return;
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      final profile = LocalProfileService.instance;

      // Priority: widget params > local cache > Firebase
      final uid  = widget.userId.isNotEmpty
          ? widget.userId
          : (profile.localUid.isNotEmpty ? profile.localUid : (fbUser?.uid ?? 'anon'));
      final name = widget.userName.isNotEmpty
          ? widget.userName
          : (profile.localName.isNotEmpty && profile.localName != 'Турист'
              ? profile.localName
              : (fbUser?.displayName?.isNotEmpty == true ? fbUser!.displayName! : 'Турист'));

      final tripId = widget.tripId.isNotEmpty ? widget.tripId : 'demo-wave';

      await _wave.start(tripId: tripId, userId: uid, userName: name);

      _eventSub = _wave.events.listen(_onEvent);
      _peerSub  = _wave.peerEvents.listen(_onPeer);

      if (mounted) {
        setState(() {
        _isStarted = true;
        _btActive  = _wave.isBluetoothActive;
        _history   = List.from(_wave.voiceHistory);
      });
      }

      _pollMyLocation();
    } catch (e) {
      if (mounted) _snack('Ошибка запуска WAVE: $e', isError: true);
    }
  }

  /// Polls GPS up to 6 times (10 s apart) for distance display.
  void _pollMyLocation() async {
    for (var i = 0; i < 6; i++) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) setState(() { _myLat = pos.latitude; _myLng = pos.longitude; });
        return;
      } catch (_) {
        await Future.delayed(const Duration(seconds: 10));
      }
    }
  }

  void _onEvent(WaveEvent ev) {
    if (!mounted) return;
    setState(() {
      if (ev is WaveBtStatusEvent) {
        _btActive = ev.active;
      } else if (ev is WaveBusyEvent) {
        _isBusy = ev.busy;
      } else if (ev is WaveVoiceReceivedEvent) {
        _liveTransmitter = ev.userName;
        // Clear "live" indicator after 3 s
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _liveTransmitter = null);
        });
      } else if (ev is WaveVoiceHistoryUpdatedEvent) {
        _history = List.from(ev.history);
      }
    });
  }

  void _onPeer(OfflinePeer peer) {
    if (!mounted) return;
    setState(() {
      final idx = _peers.indexWhere((p) => p.peerId == peer.peerId);
      if (idx >= 0) {
        _peers[idx] = peer;
      } else {
        _peers.add(peer);
      }
    });
  }

  // ── PTT ───────────────────────────────────────────────────────────────────


  Future<void> _startPtt() async {
    if (!_btActive) { _snack('Bluetooth недоступен', isError: true); return; }
    if (_isRecording || _isBusy) return;
    final ok = await _wave.startRecording();
    if (ok && mounted) {
      setState(() => _isRecording = true);
      _pttCtrl.forward();
    }
  }

  Future<void> _stopPtt() async {
    if (!_isRecording || _lockPtt) return; // locked → don't stop
    await _endPtt();
  }

  Future<void> _endPtt() async {
    if (!_isRecording) return;
    setState(() { _isRecording = false; _lockPtt = false; });
    _pttCtrl.reverse();
    await _wave.stopRecordingAndSend();
  }

  void _onPttVerticalDrag(DragUpdateDetails details) {
    if (details.delta.dy < _lockThreshold || details.localPosition.dy < _lockThreshold) return;
    if (_isRecording && !_lockPtt) {
      setState(() => _lockPtt = true);
      _snack('🔒 Запись заблокирована — нажмите кнопку чтобы остановить');
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? context.errorColor : AppColors.accent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isBusy) {
          final reason = _wave.isSending ? '📡 Отправка…' : '🛎 Воспроизведение…';
          _snack('Подождите: $reason');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildStatusBanner(),
            if (_liveTransmitter != null) _buildLiveToast(_liveTransmitter!),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildVoiceTab(),
                  _buildParticipantsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: _isBusy ? AppColors.textSecondary : AppColors.textPrimary),
        onPressed: _isBusy ? null : () => context.pop(),
      ),
      title: Row(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _isStarted ? _pulseAnim.value : 1.0, child: child),
          child: Icon(LucideIcons.radio,
              color: _isRecording ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF),
              size: 20),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('WAVE',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          Text(
            _isRecording ? '🔴 В ЭФИРЕ' : 'Bluetooth Mesh',
            style: TextStyle(
              color: _isRecording ? const Color(0xFFFF3B30) : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ]),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _btActive
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _btActive
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '${_peers.length + 1} уч.',
                style: TextStyle(
                  color: _btActive ? const Color(0xFF00E5FF) : Colors.grey,
                  fontSize: 12, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Status Banner ─────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    if (_isBusy) {
      final reason = _wave.isSending ? 'Отправка…' : 'Воспроизведение…';
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation(Colors.amber))),
          const SizedBox(width: 10),
          Text('📳 $reason Навигация заблокирована',
              style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    Color color; String label; IconData icon;
    if (!_isStarted) {
      color = context.errorColor; label = 'Инициализация...'; icon = LucideIcons.loader;
    } else if (!_btActive) {
      color = Colors.orange; label = '⏳ Ожидание Bluetooth...'; icon = LucideIcons.bluetooth;
    } else {
      color = const Color(0xFF00E5FF);
      label = '● Сеть WAVE активна · ${_peers.length + 1} уч.';
      icon = LucideIcons.radio;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  /// Red "LIVE" banner that appears when a peer is transmitting.
  Widget _buildLiveToast(String name) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.mic, color: Color(0xFFFF3B30), size: 14),
        const SizedBox(width: 8),
        Text('$name в эфире',
            style: const TextStyle(
                color: Color(0xFFFF3B30), fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.mic_outlined, size: 18), text: 'Голос'),
          Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Участники'),
        ],
      ),
    );
  }

  // ── Voice Tab (history + PTT) ─────────────────────────────────────────────

  Widget _buildVoiceTab() {
    return Column(
      children: [
        // History list
        Expanded(child: _history.isEmpty ? _buildEmptyHistory() : _buildHistoryList()),
        // Zello-like PTT button zone
        _buildPttZone(),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.radioTower, size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text('Удерживайте кнопку для передачи',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Входящие голосовые сообщения появятся здесь',
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
      ]),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      itemCount: _history.length,
      itemBuilder: (_, i) => _buildHistoryTile(_history[i]),
    );
  }

  Widget _buildHistoryTile(ReceivedVoiceMessage msg) {
    final timeStr = _formatTime(msg.receivedAt);
    final dur     = msg.durationSec > 0 ? '${msg.durationSec}с' : '';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          child: Text(
            msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.senderName,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$timeStr${dur.isNotEmpty ? '  ⏱ $dur' : ''}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ])),
        // Play / Replay button
        GestureDetector(
          onTap: () => _wave.replayMessage(msg),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: 20),
          ),
        ),
      ]),
    );
  }

  // ── PTT Button Zone (Zello-like) ──────────────────────────────────────────

  Widget _buildPttZone() {
    final isActive = _isRecording;
    final color    = isActive ? const Color(0xFFFF3B30) : AppColors.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
      ),
      child: Column(children: [
        // Lock / status hint
        if (_lockPtt)
          _buildLockIndicator()
        else
          Text(
            isActive ? '🔴 Говорите...' : 'Удержите для передачи',
            style: TextStyle(
              color: isActive ? const Color(0xFFFF3B30) : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        const SizedBox(height: 12),
        // Main PTT button with drag-up to lock
        GestureDetector(
          onVerticalDragUpdate: _onPttVerticalDrag,
          child: GestureDetector(
            onTapDown: (_) => _startPtt(),
            onTapUp: (_) => _stopPtt(),
            onTapCancel: () => _stopPtt(),
            child: ScaleTransition(
              scale: _pttAnim,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    color.withValues(alpha: isActive ? 1.0 : 0.9),
                    color.withValues(alpha: isActive ? 0.75 : 0.6),
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isActive ? 0.55 : 0.3),
                      blurRadius: isActive ? 28 : 14,
                      spreadRadius: isActive ? 6 : 2,
                    ),
                  ],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _lockPtt ? Icons.lock_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  if (_lockPtt)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('СТОП', style: TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!_lockPtt && !isActive)
          Text('↑ Потяните вверх для блокировки',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10)),
        // When locked — show big tap-to-stop button
        if (_lockPtt) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _endPtt,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.5)),
              ),
              child: const Text('⏹ Остановить передачу',
                  style: TextStyle(color: Color(0xFFFF3B30), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildLockIndicator() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFFF3B30)),
      const SizedBox(width: 4),
      Text('Передача заблокирована',
          style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }

  // ── Participants Tab ──────────────────────────────────────────────────────

  Widget _buildParticipantsTab() {
    final allPeers = _peers;
    return allPeers.isEmpty
        ? Center(child: Text('Нет других участников',
            style: TextStyle(color: AppColors.textSecondary)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: allPeers.length,
            itemBuilder: (_, i) => _buildPeerTile(allPeers[i]),
          );
  }

  Widget _buildPeerTile(OfflinePeer peer) {
    final dist = (_myLat != null && _myLng != null &&
            peer.lat != null && peer.lng != null)
        ? WaveService.formatDistance(
            WaveService.distanceMeters(_myLat!, _myLng!, peer.lat!, peer.lng!))
        : null;

    final lastSeenSec = DateTime.now().difference(peer.lastSeen).inSeconds;
    final online = lastSeenSec < 30;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: peer.sosBroadcasting
            ? context.errorColor.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: peer.sosBroadcasting
              ? context.errorColor.withValues(alpha: 0.4)
              : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        Stack(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (peer.sosBroadcasting
                    ? context.errorColor
                    : AppColors.accent)
                .withValues(alpha: 0.15),
            child: Text(
              (peer.userName ?? '').isNotEmpty ? (peer.userName ?? '')[0].toUpperCase() : '?',
              style: TextStyle(
                color: peer.sosBroadcasting ? context.errorColor : AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Positioned(bottom: 0, right: 0,
              child: Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFF00E5FF) : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 1.5),
                  ))),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(peer.userName ?? '',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w600)),
            if (peer.sosBroadcasting) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: context.errorColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('SOS', style: TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(
            dist != null ? '📍 $dist' : 'В сети',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ])),
        Icon(LucideIcons.radio,
            size: 16,
            color: online ? const Color(0xFF00E5FF) : Colors.grey.withValues(alpha: 0.4)),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inMinutes < 1) return 'только что';
    if (now.day == dt.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
