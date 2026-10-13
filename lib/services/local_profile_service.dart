import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches the authenticated user's profile locally so MESH can identify
/// the device even when there is no internet connection.
///
/// **Contract**:
/// - [saveFromFirebase] is called after every successful sign-in / profile update
///   (requires internet). It writes the freshest values from Firebase.
/// - [localName] / [localUid] are always readable — they fall back to Firebase
///   in-memory data or a generic placeholder if nothing has been cached yet.
class LocalProfileService {
  LocalProfileService._();
  static final LocalProfileService instance = LocalProfileService._();

  static const _keyName = 'local_profile_name';
  static const _keyUid  = 'local_profile_uid';

  // In-memory cache (populated by init())
  String _name = 'Турист';
  String _uid  = '';

  String get localName => _name;
  String get localUid  => _uid;

  /// Must be called once at app start (after Firebase init).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Read persisted values first
    final savedName = prefs.getString(_keyName);
    final savedUid  = prefs.getString(_keyUid);

    // Try to complement/override with live Firebase data (may be null if offline)
    final fbUser = FirebaseAuth.instance.currentUser;

    _uid  = fbUser?.uid  ?? savedUid  ?? '';
    _name = fbUser?.displayName?.isNotEmpty == true
        ? fbUser!.displayName!
        : (savedName ?? 'Турист');

    // Persist whatever we resolved (so next cold-start offline still works)
    if (_uid.isNotEmpty)  await prefs.setString(_keyUid,  _uid);
    if (_name != 'Турист') await prefs.setString(_keyName, _name);
  }

  /// Call after a successful Firebase profile update (name change etc.)
  Future<void> saveFromFirebase() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (fbUser.displayName?.isNotEmpty == true) {
      _name = fbUser.displayName!;
      await prefs.setString(_keyName, _name);
    }
    _uid = fbUser.uid;
    await prefs.setString(_keyUid, _uid);
  }

  /// Manually update the cached name (e.g. after editing profile).
  Future<void> setName(String name) async {
    _name = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }
}
