class AuthHelpers {
  AuthHelpers._();

  static bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
