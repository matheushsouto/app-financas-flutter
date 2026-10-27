import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Mantém toda a lógica do [AuthService] (Firebase) e acrescenta o login
/// na API Laravel, fazendo a autenticação nos dois lugares.
class AuthServiceLaravel extends AuthService {
  AuthServiceLaravel({super.firebaseAuth});

  static const String _baseUrl =
      'https://paradigmas-prog-20262-production-5nzzq5.laravel.cloud';

  /// Token Bearer retornado por POST /login (Sanctum).
  static String? token;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _loginLaravel(email: email, password: password);
    await super.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    token = null;
    await super.signOut();
  }

  Future<void> _loginLaravel({
    required String email,
    required String password,
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(
              <String, String>{'email': email.trim(), 'password': password},
            ),
          )
          .timeout(const Duration(seconds: 15));
      final String body = response.body;

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(body);
        final dynamic received = data is Map ? data['token'] : null;
        if (received is! String || received.isEmpty) {
          throw AuthException('Não foi possível entrar.');
        }
        token = received;
        return;
      }
      if (response.statusCode == 401) {
        throw AuthException('E-mail ou senha incorretos');
      }
      if (response.statusCode == 422) {
        throw AuthException('E-mail ou senha inválidos.');
      }
      throw AuthException('Não foi possível entrar.');
    } on http.ClientException {
      throw AuthException('Sem conexão com a internet.');
    } on TimeoutException {
      throw AuthException('Sem conexão com a internet.');
    } on FormatException {
      throw AuthException('Não foi possível entrar.');
    }
  }
}
