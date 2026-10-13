import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'local_profile_service.dart';
import 'mesh_service.dart';

/// Watches network connectivity and activates the WAVE module automatically
/// whenever the device loses internet access.
///
/// Lifecycle: call [init()] once in main() after [AuthService.init()].
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Initialises the connectivity watcher. Should be called in main().
  Future<void> init() async {
    // Check current state synchronously before any subscription fires
    final result = await Connectivity().checkConnectivity();
    _isOnline = _hasInternet(result);

    if (!_isOnline) _onWentOffline();

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = _hasInternet(results);
      if (online == _isOnline) return; // no state change
      _isOnline = online;
      notifyListeners();
      if (!online) {
        _onWentOffline();
      } else {
        _onCameOnline();
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _hasInternet(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  void _onWentOffline() {
    debugPrint('[ConnectivityService] 📴 offline → starting MESH');
    _ensureMeshRunning();
  }

  void _onCameOnline() {
    debugPrint('[ConnectivityService] 🌐 back online — refreshing profile');
    // Non-blocking refresh of local profile from Firebase
    LocalProfileService.instance.saveFromFirebase();
  }

  void _ensureMeshRunning() {
    final mesh    = MeshService.instance;
    final profile = LocalProfileService.instance;

    if (mesh.isStarted) return;           // already active — do nothing
    if (profile.localUid.isEmpty) return; // user not logged in yet

    mesh.start(
      roomId:   'explora-mesh',
      userId:   profile.localUid,
      userName: profile.localName,
    );
  }



  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
