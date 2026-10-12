import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/service/google_sign_in_config.dart';

void main() {
  group('GoogleSignInConfig.resolveWebClientId', () {
    test('usa o client web padrão quando o dart-define vem vazio', () {
      expect(
        GoogleSignInConfig.resolveWebClientId(''),
        GoogleSignInConfig.defaultWebClientId,
      );
      expect(
        GoogleSignInConfig.resolveWebClientId('   '),
        GoogleSignInConfig.defaultWebClientId,
      );
    });

    test('respeita o client id explícito do dart-define', () {
      const custom = '123-abc.apps.googleusercontent.com';
      expect(GoogleSignInConfig.resolveWebClientId(custom), custom);
    });
  });
}
