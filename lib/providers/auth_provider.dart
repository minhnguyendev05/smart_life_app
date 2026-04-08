import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:google_sign_in/google_sign_in.dart';

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

  void _bypassAuth() {
    // Xóa chữ 'const' ở đây vì AppUser constructor không phải const
    _currentUser = AppUser(
      id: 'mock_user_123',
      email: 'guest@example.com',
      displayName: 'Guest User',
    );
    _profile = UserProfile(
      id: 'mock_user_123',
      fullName: 'Guest User',
      email: 'guest@example.com',
      role: UserRole.user,
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
    _bypassAuth();
    notifyListeners();
    return true;
  }

  Future<bool> signInWithGoogle() async {
    _bypassAuth();
    notifyListeners();
    return true;
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
