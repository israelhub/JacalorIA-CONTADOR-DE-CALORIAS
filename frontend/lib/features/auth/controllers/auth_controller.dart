import 'package:flutter/material.dart';

import '../service/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool isLoading = false;
  String? error;
  String? token;
  Map<String, dynamic>? currentUser;

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _service.signInWithGoogle();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    error = null;
    try {
      await _service.createAccount(
        name: name,
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    error = null;
    try {
      final result = await _service.signIn(email: email, password: password);
      token = result['token'];
      currentUser = result['user'];
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    _setLoading(true);
    error = null;
    try {
      final result = await _service.verifyEmail(email: email, code: code);
      token = result['token'];
      currentUser = result['user'];
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendCode({required String email}) async {
    _setLoading(true);
    error = null;
    try {
      await _service.resendCode(email: email);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
