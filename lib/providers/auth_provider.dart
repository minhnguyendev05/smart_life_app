import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserProfile _profile = UserProfile(
    id: 'guest_user', 
    email: 'guest@smartlife.com', 
    fullName: 'Người dùng Khách'
  );
  
  bool _loading = false;
  String? _authError;
  bool _biometricEnabled = false;
  
  // LUÔN CHO VÀO TRONG ĐỂ TEST MEMBER 3
  bool _bypassAuth = true; 

  UserProfile get profile => _profile;
  bool get loading => _loading;
  String? get authError => _authError;
  bool get isAuthenticated => _bypassAuth; // Luôn trả về true
  bool get isAdmin => false;
  bool get biometricEnabled => _biometricEnabled;

  void setBypass(bool value) {
    _bypassAuth = value;
    notifyListeners();
  }

  Future<void> toggleBiometric() async {
    _biometricEnabled = !_biometricEnabled;
    notifyListeners();
  }

  Future<bool> verifyBiometricForSensitiveAction() async {
    return true; // Tạm thời bỏ qua bảo mật vân tay để bạn test cho nhanh
  }

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return true; // Luôn thành công
  }

  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _profile = UserProfile(id: 'guest_user', email: email, fullName: fullName);
    notifyListeners();
    return true; // Luôn thành công
  }

  Future<bool> signInWithGoogle() async {
    // Tạm thời vô hiệu hóa Google Sign In vì lỗi thư viện trên máy bạn
    return true; 
  }

  Future<void> signOut() async {
    _bypassAuth = false;
    _profile = UserProfile(id: '', email: '', fullName: '');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
