import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';
import '../core/google_config.dart';

class AuthUser {
  const AuthUser({required this.name, required this.email});

  final String name;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<AuthUser> signInWithEmail(String email, String password);

  Future<void> iniciarGoogle();

  Stream<AuthUser> get googleLogins;

  Future<AuthUser?> restoreSession();

  Future<void> signOut();
}

class ApiAuthService implements AuthService {
  ApiAuthService(this._api);

  static const _tokenKey = 'auth_token';

  final ApiClient _api;
  bool _googleIniciado = false;
  final _googleLogins = StreamController<AuthUser>.broadcast();

  @override
  Stream<AuthUser> get googleLogins => _googleLogins.stream;

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final corpo = await _api.postJson('/auth/login', {'email': email, 'senha': password})
          as Map<String, dynamic>;
      final token = corpo['access_token'] as String;
      _api.setToken(token);
      await _salvarToken(token);
      return _usuarioDe(corpo['usuario'] as Map<String, dynamic>);
    } on AppException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> iniciarGoogle() async {
    if (_googleIniciado) return;
    _googleIniciado = true;
    await GoogleSignIn.instance.initialize(clientId: googleClientId);
    GoogleSignIn.instance.authenticationEvents.listen(
      (evento) async {
        if (evento is! GoogleSignInAuthenticationEventSignIn) return;
        try {
          _googleLogins.add(await _entrarComIdToken(evento.user.authentication.idToken));
        } catch (e) {
          _googleLogins.addError(_erroGoogle(e));
        }
      },
      onError: (Object e) => _googleLogins.addError(_erroGoogle(e)),
    );
  }

  Future<AuthUser> _entrarComIdToken(String? idToken) async {
    if (idToken == null) {
      throw const AuthException('Não foi possível obter a conta do Google.');
    }
    final corpo = await _api.postJson('/auth/google', {'id_token': idToken})
        as Map<String, dynamic>;
    final token = corpo['access_token'] as String;
    _api.setToken(token);
    await _salvarToken(token);
    return _usuarioDe(corpo['usuario'] as Map<String, dynamic>);
  }

  AuthException _erroGoogle(Object e) => switch (e) {
        AuthException() => e,
        AppException() => AuthException(e.message), // 401 "Conta Google não autorizada"
        GoogleSignInException(code: GoogleSignInExceptionCode.canceled) =>
          const AuthException('Login com Google cancelado.'),
        _ => const AuthException('Não foi possível entrar com o Google. Tente novamente.'),
      };

  @override
  Future<AuthUser?> restoreSession() async {
    final String? token;
    try {
      token = (await SharedPreferences.getInstance()).getString(_tokenKey);
    } catch (_) {
      return null;
    }
    if (token == null || token.isEmpty) return null;

    _api.setToken(token);
    try {
      final corpo = await _api.get('/auth/me') as Map<String, dynamic>;
      final dados = (corpo['usuario'] ?? corpo) as Map<String, dynamic>;
      return _usuarioDe(dados);
    } catch (_) {
      await signOut();
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    _api.setToken(null);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
    }
    try {
      await (await SharedPreferences.getInstance()).remove(_tokenKey);
    } catch (_) {
    }
  }

  Future<void> _salvarToken(String token) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
    } catch (_) {
    }
  }

  AuthUser _usuarioDe(Map<String, dynamic> dados) =>
      AuthUser(name: dados['nome'] as String, email: dados['email'] as String);
}
