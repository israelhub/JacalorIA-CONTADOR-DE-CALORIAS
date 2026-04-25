import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    // Se estiver rodando na Web (localhost funciona)
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    // Se estiver no Android Emulator, 10.0.2.2 aponta para o localhost da máquina host
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Nota: Se estiver usando um dispositivo FÍSICO, você DEVE usar o IP da sua rede ou NGROK
      // Para facilitar, vamos permitir mudar isso aqui centralizadamente.
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }
}
