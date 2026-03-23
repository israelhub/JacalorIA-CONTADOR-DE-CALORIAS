import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = '';

  Future<void> signInWithGoogle() async {
    throw UnimplementedError('signInWithGoogle ainda não implementado');
  }

  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');
    await http.post(uri, body: {'email': email, 'password': password});
    throw UnimplementedError('createAccount ainda não implementado');
  }

  Future<void> signIn({required String email, required String password}) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    await http.post(uri, body: {'email': email, 'password': password});
    throw UnimplementedError('signIn ainda não implementado');
  }
}
