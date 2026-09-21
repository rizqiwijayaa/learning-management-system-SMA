import 'package:flutter/foundation.dart';
import 'package:lms_guru/roles/guru/models/user_profile.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileStore extends ChangeNotifier {
  ProfileStore._();

  static final ProfileStore instance = ProfileStore._();

  final LmsApiService _api = LmsApiService();
  static const String _rememberMeKey = 'remember_me_enabled';
  static const String _rememberedEmailKey = 'remembered_email';
  UserProfile? _profile;
  bool _isLoading = false;
  bool _hasLoaded = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> ensureLoaded({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !force) return;

    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _api.getProfile(
        id: _profile?.id,
        nip: _profile?.nip,
        email: _profile?.email,
      );
    } catch (_) {
      _profile ??= null;
    } finally {
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    final saved = await _api.updateProfile(profile);
    _profile = saved;
    _hasLoaded = true;
    notifyListeners();
    return saved;
  }

  void setProfile(UserProfile profile) {
    _profile = profile;
    _hasLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> persistRememberedLogin({
    required bool rememberMe,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe && email.trim().isNotEmpty) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_rememberedEmailKey, email.trim());
      return;
    }

    await prefs.remove(_rememberMeKey);
    await prefs.remove(_rememberedEmailKey);
  }

  Future<({bool rememberMe, String email})> getRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final email = prefs.getString(_rememberedEmailKey) ?? '';
    return (rememberMe: rememberMe, email: rememberMe ? email : '');
  }

  Future<void> clearRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_rememberedEmailKey);
  }

  void clear() {
    _profile = null;
    _hasLoaded = false;
    _isLoading = false;
    notifyListeners();
  }
}
