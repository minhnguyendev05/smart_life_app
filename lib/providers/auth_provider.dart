import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../models/user_profile.dart';
import '../config/app_secrets.dart';
import '../services/app_user_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/cloudinary_upload_service.dart';
import '../services/firebase_core_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _hydrateFromFirebase();
  }

  final BiometricAuthService _biometricService = BiometricAuthService();
  final AppUserService _appUserService = AppUserService();
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
  bool get isAuthenticated => _currentUser.id.isNotEmpty;
  bool get isAdmin => _profile.role == UserRole.admin;

  UserRole _deriveRole(String? email) {
    final normalized = (email ?? '').toLowerCase();
    return normalized.contains('admin') ? UserRole.admin : UserRole.user;
  }

  Future<GoogleSignInAccount?> _googleAuthenticate() async {
    await GoogleSignIn.instance.initialize(
      clientId: AppSecrets.googleWebClientId.isEmpty ? null : AppSecrets.googleWebClientId,
      serverClientId: AppSecrets.googleServerClientId.isEmpty
          ? null
          : AppSecrets.googleServerClientId,
    );

    GoogleSignInAccount? user;
    final lightweight = GoogleSignIn.instance.attemptLightweightAuthentication();
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

    final safeAccessToken =
        (accessToken == null || accessToken.isEmpty) ? null : accessToken;
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

  bool _ensureAuthReady() {
    if (FirebaseCoreService.isReady) {
      return true;
    }
    _authError =
        'Firebase chưa sẵn sàng. Vui lòng cấu hình Firebase và chạy lại trên Android/iOS/Web.';
    return false;
  }

  String _mapAuthError(Object error) {
    if (error is MissingPluginException) {
      return 'Firebase Auth chưa được đăng ký trên nền tảng hiện tại. Hãy chạy trên Android/iOS/Web hoặc kiểm tra cấu hình plugin.';
    }
    if (error is PlatformException &&
        (error.code.contains('channel-error') ||
            (error.message ?? '').contains('FirebaseAuthHostApi'))) {
      return 'Không kết nối được plugin Firebase Auth. Hãy chạy `flutter clean`, `flutter pub get` rồi build lại.';
    }
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }

  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _authError = null;
    try {
      if (!_ensureAuthReady()) return false;

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) {
        _authError = 'Không thể tạo tài khoản.';
        return false;
      }
      await _bootstrapAppUser(user, preferredName: fullName);
      return true;
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Đăng ký thất bại.';
      return false;
    } catch (e) {
      _authError = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _authError = null;
    try {
      if (!_ensureAuthReady()) return false;

      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) {
        _authError = 'Không tìm thấy người dùng đăng nhập.';
        return false;
      }
      await _bootstrapAppUser(user);
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
        await _bootstrapAppUser(user);
        return true;
      }

      final googleUser = await _googleAuthenticate();
      if (googleUser == null) {
        _authError = 'Không thể đăng nhập Google.';
        return false;
      }

      final credential = await _buildGoogleCredential(googleUser);
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        await _bootstrapAppUser(user, preferredName: googleUser.displayName);
      } else {
        _syncProfileFromAppUser(
          AppUser(
            id: googleUser.id,
            email: googleUser.email,
            displayName: googleUser.displayName ?? googleUser.email,
          ),
        );
      }
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
    try {
      if (FirebaseCoreService.isReady) {
        await FirebaseAuth.instance.signOut();
      }
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Continue to force local logout state even if plugin call fails.
    } finally {
      _searchResults = const <AppUser>[];
      _searchingUsers = false;
      _currentUser = AppUser.empty();
      _profile = _profile.copyWith(
        id: '',
        email: '',
        fullName: '',
        role: UserRole.user,
      );
      _authError = null;
      notifyListeners();
    }
  }

  Future<void> toggleBiometric() async {
    if (!_biometricEnabled) {
      final ok = await _biometricService.authenticate(
        reason: 'Bật khóa sinh trắc học cho SmartLife',
      );
      if (!ok) {
        _authError = 'Không thể xác thực sinh trắc học trên thiết bị này.';
        notifyListeners();
        return;
      }
    }
    _biometricEnabled = !_biometricEnabled;
    notifyListeners();
  }

  Future<bool> verifyBiometricForSensitiveAction() async {
    if (!_biometricEnabled) {
      return true;
    }
    final ok = await _biometricService.authenticate(
      reason: 'Xác thực để mở tính năng nhạy cảm',
    );
    if (!ok) {
      _authError = 'Xác thực sinh trắc học thất bại.';
      notifyListeners();
    }
    return ok;
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      _searchResults = const <AppUser>[];
      _searchingUsers = false;
      notifyListeners();
      return;
    }

    _searchingUsers = true;
    notifyListeners();
    try {
      _searchResults = await _appUserService.searchUsers(
        query: normalized,
        currentUserId: userId,
      );
    } catch (e) {
      _authError = e.toString();
    } finally {
      _searchingUsers = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults = const <AppUser>[];
    _searchingUsers = false;
    notifyListeners();
  }

  Future<bool> updateProfileInfo({
    required String displayName,
    String? avatarUrl,
  }) async {
    if (userId.isEmpty) {
      return false;
    }
    final normalized = displayName.trim();
    if (normalized.isEmpty) {
      _authError = 'Tên hiển thị không được để trống.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _authError = null;
    try {
      final next = await _appUserService.updateProfile(
        userId: userId,
        displayName: normalized,
        avatarUrl: avatarUrl,
      );
      if (next == null) {
        _authError = 'Không thể cập nhật hồ sơ.';
        return false;
      }
      _syncProfileFromAppUser(next);
      return true;
    } catch (e) {
      _authError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadAvatarAndSave({
    required List<int> bytes,
    required String filename,
  }) async {
    if (userId.isEmpty) {
      return false;
    }

    _setLoading(true);
    _authError = null;
    try {
      final url = await _uploadService.uploadBytes(
        bytes: bytes,
        filename: filename,
        folder: 'smart_users/avatar',
      );
      if (url == null || url.isEmpty) {
        _authError = 'Upload avatar thất bại. Kiểm tra Cloudinary config.';
        return false;
      }
      return updateProfileInfo(
        displayName: _currentUser.displayName,
        avatarUrl: url,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> _bootstrapAppUser(User firebaseUser, {String? preferredName}) async {
    final appUser = await _appUserService.ensureUserFromAuth(
      firebaseUser,
      preferredName: preferredName,
    );
    _syncProfileFromAppUser(appUser);
    await _saveFcmToken(appUser.id);
  }

  void _syncProfileFromAppUser(AppUser user) {
    final role = _deriveRole(user.email);
    _currentUser = user;
    _profile = _profile.copyWith(
      id: user.id,
      fullName: user.displayName,
      email: user.email,
      avatarUrl: user.avatarUrl,
      role: role,
    );
    notifyListeners();
  }

  Future<void> _saveFcmToken(String uid) async {
    if (uid.isEmpty || !FirebaseCoreService.isReady) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb && AppSecrets.fcmWebVapidKey.isNotEmpty
            ? AppSecrets.fcmWebVapidKey
            : null,
      );
      if (token == null || token.trim().isEmpty) {
        return;
      }
      await _appUserService.saveFcmToken(userId: uid, token: token);
    } catch (_) {
      // Best-effort only: token sync failures should not block auth flow.
    }
  }

  Future<void> _hydrateFromFirebase() async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await _bootstrapAppUser(user);
  }
}
