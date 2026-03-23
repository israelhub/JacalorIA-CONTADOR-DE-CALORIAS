import 'package:flutter/material.dart';

import '../service/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool isLoading = false;
  String? error;

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

  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _service.createAccount(email: email, password: password);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _service.signIn(email: email, password: password);
    } catch (e) {
      error = e.toString();
      notifyListeners();
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
