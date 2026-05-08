class AuthHelpers {
  AuthHelpers._();

  static const passwordRequirementsMessage =
      'A senha deve ter no minimo 8 caracteres, com letra maiuscula, '
      'letra minuscula, numero e caractere especial.';

  static bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  }
}
