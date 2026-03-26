import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_profile.dart';
import '../config/app_secrets.dart';
import '../services/biometric_auth_service.dart';
import '../services/firebase_core_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _hydrateFromFirebase();
  }

  final BiometricAuthService _biometricService = BiometricAuthService();

  UserProfile _profile = UserProfile(
    id: '',
    fullName: '',
    email: '',
    role: UserRole.user,
  );

  bool _biometricEnabled = false;
  bool _loading = false;
  String? _authError;

  UserProfile get profile => _profile;
  bool get biometricEnabled => _biometricEnabled;
  bool get loading => _loading;
  String? get authError => _authError;
  bool get isAuthenticated => _profile.id.isNotEmpty;
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
      _profile = _profile.copyWith(
        id: user?.uid,
        fullName: fullName?.trim().isNotEmpty == true
            ? fullName!.trim()
            : _profile.fullName,
        email: user?.email ?? email,
        role: _deriveRole(user?.email ?? email),
      );
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

      final googleUser = await _googleAuthenticate();
      if (googleUser == null) {
        _authError = 'Không thể đăng nhập Google.';
        return false;
      }

      final auth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
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

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> _hydrateFromFirebase() async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    _profile = _profile.copyWith(
      id: user.uid,
      email: user.email ?? _profile.email,
      role: _deriveRole(user.email ?? _profile.email),
    );
    notifyListeners();
  }
}
