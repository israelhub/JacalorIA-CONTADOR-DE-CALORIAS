import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/auth_service.dart';

class AuthController extends ChangeNotifier {
  static const _newAccountFirstHomeAccessKeyPrefix =
      'new_account_first_home_access_';
  final AuthService _service = AuthService();

  bool isLoading = false;
  String? error;
  String? token;
  bool shouldCompleteOnboarding = false;
  Map<String, dynamic>? currentUser;

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    error = null;
    shouldCompleteOnboarding = false;
    try {
      final result = await _service.signInWithGoogle();
      final rawToken = result['token'] ?? (result['data']?['token']);
      final rawUser = result['user'] ?? (result['data']?['user']);

      if (rawToken is! String || rawToken.trim().isEmpty) {
        final rawMessage = result['message'];
        error = rawMessage is String && rawMessage.trim().isNotEmpty
            ? rawMessage.trim()
            : 'Login com Google retornou sem token. Tente novamente.';
        notifyListeners();
        return;
      }

      token = rawToken;
      shouldCompleteOnboarding =
          result['isNewUser'] == true || result['needsOnboarding'] == true;
      currentUser = rawUser is Map
          ? Map<String, dynamic>.from(rawUser)
          : null;
      AuthService.globalToken = token;
      AuthService.globalUser = currentUser;

      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('auth_token', token!);
      }
      if (currentUser != null) {
        await prefs.setString('auth_user', jsonEncode(currentUser));
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
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
      AuthService.globalToken = token;
      AuthService.globalUser = currentUser;

      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('auth_token', token!);
      }
      if (currentUser != null) {
        await prefs.setString('auth_user', jsonEncode(currentUser));
      }

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
      AuthService.globalToken = token;
      AuthService.globalUser = currentUser;

      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('auth_token', token!);
      }
      if (currentUser != null) {
        await prefs.setString('auth_user', jsonEncode(currentUser));
      }
      if (currentUser != null) {
        final rawUserId =
            currentUser!['id'] ??
            currentUser!['email'] ??
            currentUser!['name'] ??
            'unknown-user';
        final userId = rawUserId.toString().trim();
        await prefs.setBool(
          '$_newAccountFirstHomeAccessKeyPrefix$userId',
          true,
        );
      }

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

  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    error = null;
    try {
      await _service.forgotPassword(email: email);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);
    error = null;
    try {
      await _service.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
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

  Future<bool> validateResetCode({
    required String email,
    required String code,
  }) async {
    _setLoading(true);
    error = null;
    try {
      await _service.validateResetCode(email: email, code: code);
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
