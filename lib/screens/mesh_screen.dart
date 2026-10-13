import '../theme/app_colors.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/offline_models.dart';
import '../services/local_profile_service.dart';
import '../services/mesh_service.dart';

/// Offline MESH screen — shows nearby peers and allows text messaging
/// via Bridgefy BLE mesh without any internet connection.
class MeshScreen extends StatefulWidget {
  const MeshScreen({super.key});

  @override
  State<MeshScreen> createState() => _MeshScreenState();
}

class _MeshScreenState extends State<MeshScreen>
    with SingleTickerProviderStateMixin {
  final _mesh = MeshService.instance;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  StreamSubscription<MeshEvent>? _eventSub;
  StreamSubscription<OfflinePeer>? _peerSub;

  bool _meshActive = false;
  List<OfflinePeer> _peers = [];
  List<MeshTextMessage> _messages = [];
  bool _isSending = false;
  Position? _myPosition;
  StreamSubscription<Position>? _posSub;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _meshActive = _mesh.isStarted && _mesh.isBluetoothActive;
    _messages = List.from(_mesh.textHistory);
    _peers = List.from(_mesh.nearbyPeers);

    _eventSub = _mesh.events.listen(_onEvent);
    _peerSub = _mesh.peerEvents.listen(_onPeer);

    // Start Geolocator FIRST so its location permission request runs before
    // Bridgefy's BLE permission request. Android rejects concurrent permission
    // dialogs with "Can request only one set of permissions at a time", which
    // silently blocks ALL grants including BLE → MESH never starts.
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
      ),
    ).listen(
      (p) { if (mounted) setState(() => _myPosition = p); },
      onError: (_) {}, // ignore PermissionDeniedException
      cancelOnError: false,
    );

    // Defer MESH start to post-frame so Geolocator's permission request
    // completes before Bridgefy requests BLE permissions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_mesh.isStarted) {
        final profile = LocalProfileService.instance;
        MeshService.instance.start(
          roomId:   'explora-mesh',
          userId:   profile.localUid,
          userName: profile.localName,
        );
      } else if (_mesh.isBluetoothActive) {
        // Hot restart: MESH already up — refresh peer list with a presence ping
        _mesh.sendPresencePingNow();
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _peerSub?.cancel();
    _posSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onEvent(MeshEvent event) {
    if (!mounted) return;
    if (event is MeshBtStatusEvent) {
      // Читаем актуальный статус из сервиса — не полагаемся на кэшированное event.active
      final active = _mesh.isStarted && _mesh.isBluetoothActive;
      setState(() => _meshActive = active);
      if (!active) {
        final err = (_mesh.btErrorMessage ?? '').toLowerCase();
        if (err.contains('location')) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) { if (mounted) _showLocationDisabledDialog(); },
          );
        }
      }
    } else if (event is MeshTextHistoryUpdatedEvent) {
      setState(() => _messages = List.from(event.history));
    } else if (event is MeshSosReceivedEvent) {
      _showSosAlert(event);
    }
  }

  void _onPeer(OfflinePeer peer) {
    if (!mounted) return;
    setState(() {
      _peers = List.from(_mesh.nearbyPeers);
    });
  }

  void _showLocationDisabledDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Геолокация выключена'),
        content: const Text(
          'Для работы MESH-сети необходимо включить геолокацию на устройстве.\n\n'
          'Откройте Настройки → Местоположение и включите службу.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Открыть настройки'),
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showSosAlert(MeshSosReceivedEvent event) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('🆘 SOS СИГНАЛ!'),
        content: Text(
          '${event.userName} отправил(а) SOS сигнал!\n'
          '${event.lat != null ? 'Координаты: ${event.lat!.toStringAsFixed(4)}°N, ${event.lng!.toStringAsFixed(4)}°E' : 'Координаты неизвестны'}',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Принято'),
            onPressed: () {
              Navigator.pop(context);
              _mesh.dismissSosAlert();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _msgCtrl.clear();
    await _mesh.sendTextMessage(text);
    setState(() => _isSending = false);
  }

  String _distanceLabel(OfflinePeer peer) {
    if (!peer.hasLocation || _myPosition == null) return '';
    final d = MeshService.distanceMeters(
      _myPosition!.latitude, _myPosition!.longitude,
      peer.lat!, peer.lng!,
    );
    return MeshService.formatDistance(d);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
        ),
        title: Column(
          children: [
            const Text(
              'MESH',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 2),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _meshActive ? const Color(0xFF00E5FF) : Colors.grey,
                  ),
                ),
                Text(
                  _meshActive
                      ? '${_peers.length} в сети'
                      : 'Поиск...',
                  style: TextStyle(
                    fontSize: 11,
                    color: _meshActive ? const Color(0xFF00E5FF) : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.messageSquare, size: 14),
                  const SizedBox(width: 6),
                  const Text('Чат'),
                  if (_messages.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_messages.length}',
                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.users, size: 14),
                  const SizedBox(width: 6),
                  const Text('Рядом'),
                  if (_peers.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_peers.length}',
                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildChatTab(isDark),
          _buildPeersTab(isDark),
        ],
      ),
    );
  }

  // ── Chat tab ───────────────────────────────────────────────────────────────

  Widget _buildChatTab(bool isDark) {
    return Column(
      children: [
        // MESH status banner
        if (!_meshActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.orange.withValues(alpha: 0.12),
            child: Row(
              children: [
                const Icon(LucideIcons.bluetoothOff, size: 14, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MESH не активен — сообщения не отправляются',
                    style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyChat()
              : ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                ),
        ),

        // Input field
        _buildMessageInput(isDark),
      ],
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.messageSquare, color: Color(0xFF00E5FF), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет сообщений',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Все сообщения передаются\nбез интернета через MESH',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MeshTextMessage msg) {
    final isMine = msg.isMine;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              child: Text(
                msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                border: Border.all(
                  color: isMine
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Text(
                      msg.senderName,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (!isMine) const SizedBox(height: 2),
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.receivedAt.hour.toString().padLeft(2, '0')}:${msg.receivedAt.minute.toString().padLeft(2, '0')}  📡',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    // Поле всегда активно — чтобы клавиатура открывалась даже при !_meshActive.
                    // Отправка блокируется отдельно через кнопку отправки.
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _meshActive ? 'Сообщение...' : 'Подключается MESH...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _meshActive ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _meshActive
                        ? const Color(0xFF00E5FF)
                        : Colors.grey.withValues(alpha: 0.25),
                    boxShadow: _meshActive
                        ? [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), blurRadius: 12)]
                        : [],
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(LucideIcons.send, color: Colors.black, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Peers tab ──────────────────────────────────────────────────────────────

  Widget _buildPeersTab(bool isDark) {
    if (_peers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.radar, color: Color(0xFF00E5FF), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Поиск участников...',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'MESH сканирует Bluetooth\nдля поиска ближайших устройств',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _peers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _buildPeerCard(_peers[i], isDark),
    );
  }

  Widget _buildPeerCard(OfflinePeer peer, bool isDark) {
    final name = peer.userName ?? 'Участник';
    final distLabel = _distanceLabel(peer);
    final isSos = peer.sosBroadcasting;
    final isRecent = DateTime.now().difference(peer.lastSeen).inSeconds < 30;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSos
                ? Colors.red.withValues(alpha: 0.1)
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSos
                  ? Colors.red.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSos
                      ? Colors.red.withValues(alpha: 0.2)
                      : const Color(0xFF00E5FF).withValues(alpha: 0.12),
                ),
                child: Center(
                  child: isSos
                      ? const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20)
                      : Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isSos ? Colors.red : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isSos) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.radio,
                          size: 11,
                          color: isRecent ? const Color(0xFF00E5FF) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MESH',
                          style: TextStyle(
                            fontSize: 11,
                            color: isRecent ? const Color(0xFF00E5FF) : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (distLabel.isNotEmpty) ...[
                          Text(
                            '  •  $distLabel',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status dot
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecent
                      ? (isSos ? Colors.red : const Color(0xFF34C759))
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
