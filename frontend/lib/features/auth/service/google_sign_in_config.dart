class GoogleSignInConfig {
  static const String defaultWebClientId =
      '618330390967-emagf9ea3j4l5kaeroi2s1bs527ugc0i.apps.googleusercontent.com';

  static String resolveWebClientId(String fromEnvironment) {
    final trimmed = fromEnvironment.trim();
    return trimmed.isEmpty ? defaultWebClientId : trimmed;
  }
}
