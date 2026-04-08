import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../models/user_profile.dart';
// import '../config/app_secrets.dart';
// import '../services/app_user_service.dart';
// import '../services/biometric_auth_service.dart';
import '../services/cloudinary_upload_service.dart';
import '../services/firebase_core_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _bypassAuth();
  }

  // final BiometricAuthService _biometricService = BiometricAuthService();
  // final AppUserService _appUserService = AppUserService();
  final CloudinaryUploadService _uploadService = CloudinaryUploadService();

  AppUser _currentUser = AppUser.empty();

  UserProfile _profile = UserProfile(
    id: '',
    fullName: '',
    email: '',
    role: UserRole.user,
  );

  bool _biometricEnabled = false;
  bool _loading = false;
  bool _searchingUsers = false;
  String? _authError;
  List<AppUser> _searchResults = const <AppUser>[];

  UserProfile get profile => _profile;
  AppUser get currentUser => _currentUser;
  bool get biometricEnabled => _biometricEnabled;
  bool get loading => _loading;
  bool get searchingUsers => _searchingUsers;
  String? get authError => _authError;
  String get userId => _currentUser.id;
  List<AppUser> get searchResults => List.unmodifiable(_searchResults);
  
  bool get isAuthenticated => true; // Luôn trả về true để vào Home
  bool get isAdmin => _profile.role == UserRole.admin;

  UserRole _deriveRole(String? email) {
    final normalized = (email ?? '').toLowerCase();
    return normalized.contains('admin') ? UserRole.admin : UserRole.user;
  }

  Future<GoogleSignInAccount?> _googleAuthenticate() async {
    await GoogleSignIn.instance.initialize(
      clientId: AppSecrets.googleWebClientId.isEmpty
          ? null
          : AppSecrets.googleWebClientId,
      serverClientId: AppSecrets.googleServerClientId.isEmpty
          ? null
          : AppSecrets.googleServerClientId,
    );

    GoogleSignInAccount? user;
    final lightweight = GoogleSignIn.instance
        .attemptLightweightAuthentication();
    if (lightweight != null) {
      user = await lightweight;
    }
    user ??= await GoogleSignIn.instance.authenticate();
    return user;
  }

  Future<OAuthCredential> _buildGoogleCredential(
    GoogleSignInAccount googleUser,
  ) async {
    final auth = googleUser.authentication;
    String? accessToken;
    final idToken = auth.idToken;

    final headers = await googleUser.authorizationClient.authorizationHeaders(
      const <String>['email', 'profile'],
      promptIfNecessary: true,
    );
    final authHeader = headers?['Authorization'] ?? headers?['authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      accessToken = authHeader.substring(7).trim();
    }

    final safeAccessToken = (accessToken == null || accessToken.isEmpty)
        ? null
        : accessToken;
    final safeIdToken = (idToken == null || idToken.isEmpty) ? null : idToken;

    if (safeAccessToken == null && safeIdToken == null) {
      throw StateError(
        'Google Sign-In không trả về accessToken/idToken hợp lệ.',
      );
    }

    return GoogleAuthProvider.credential(
      accessToken: safeAccessToken,
      idToken: safeIdToken,
    );
  }

  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _bypassAuth();
    notifyListeners();
    return true;
  }

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _authError = null;
    try {
      if (!_ensureAuthReady()) return false;

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      _profile = _profile.copyWith(
        id: user?.uid,
        email: user?.email ?? email,
        role: _deriveRole(user?.email ?? email),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Đăng nhập thất bại.';
      return false;
    } catch (e) {
      _authError = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _authError = null;
    try {
      if (!_ensureAuthReady()) return false;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final result = await FirebaseAuth.instance.signInWithPopup(provider);
        final user = result.user;
        if (user == null) {
          _authError = 'Không thể đăng nhập Google trên web.';
          return false;
        }
        _profile = _profile.copyWith(
          id: user.uid,
          email: user.email ?? _profile.email,
          fullName: user.displayName ?? _profile.fullName,
          role: _deriveRole(user.email ?? _profile.email),
        );
        return true;
      }

      final googleUser = await _googleAuthenticate();
      if (googleUser == null) {
        _authError = 'Không thể đăng nhập Google.';
        return false;
      }

      final credential = await _buildGoogleCredential(googleUser);
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = result.user;
      _profile = _profile.copyWith(
        id: user?.uid ?? googleUser.id,
        email: user?.email ?? googleUser.email,
        fullName: googleUser.displayName ?? _profile.fullName,
        role: _deriveRole(user?.email ?? googleUser.email),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Đăng nhập Google thất bại.';
      return false;
    } catch (e) {
      _authError = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    // Giữ nguyên trạng thái hoặc thoát giả
    notifyListeners();
  }

  Future<void> toggleBiometric() async {
    _biometricEnabled = !_biometricEnabled;
    notifyListeners();
  }

  Future<bool> verifyBiometricForSensitiveAction() async {
    return true;
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    notifyListeners();
  }

  void clearSearchResults() {
    notifyListeners();
  }

  Future<bool> updateProfileInfo({
    required String displayName,
    String? avatarUrl,
  }) async {
    _currentUser = _currentUser.copyWith(displayName: displayName, avatarUrl: avatarUrl);
    _profile = _profile.copyWith(fullName: displayName, avatarUrl: avatarUrl);
    notifyListeners();
    return true;
  }

  Future<bool> uploadAvatarAndSave({
    required List<int> bytes,
    required String filename,
  }) async {
    return false;
  }
}
