import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';
import '../core/google_config.dart';

/// Usuário autenticado (dados mínimos devolvidos por `POST /auth/login`).
class AuthUser {
  const AuthUser({required this.name, required this.email});

  final String name;
  final String email;
}

/// Erro de autenticação com mensagem pronta para mostrar ao usuário.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contrato de autenticação. A tela de login só conhece esta interface.
abstract class AuthService {
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> signInWithGoogle();

  /// Lê o token salvo, confere na API (`GET /auth/me`) e devolve o usuário.
  /// Devolve `null` se não há token ou se ele não vale mais (e já o apaga).
  Future<AuthUser?> restoreSession();

  /// Sai: apaga o token do [ApiClient] e do armazenamento do aparelho/navegador.
  Future<void> signOut();
}

/// Login do painel contra a API (`POST /auth/login`).
///
/// O token JWT fica no [ApiClient], que o envia nas próximas requisições, e
/// também é salvo com `shared_preferences` para sobreviver ao F5.
class ApiAuthService implements AuthService {
  ApiAuthService(this._api);

  static const _tokenKey = 'auth_token';

  final ApiClient _api;
  bool _googleIniciado = false;

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
      // A API responde 401 com "E-mail ou senha incorretos" (mensagem já pronta).
      throw AuthException(e.message);
    }
  }

  /// Pede o id_token ao Google e troca por um token do painel em `POST /auth/google`.
  /// Só entra quem está na lista fixa de admins no backend.
  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      if (!_googleIniciado) {
        await GoogleSignIn.instance.initialize(clientId: googleClientId);
        _googleIniciado = true;
      }
      final conta = await GoogleSignIn.instance.authenticate();
      final idToken = conta.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Não foi possível obter a conta do Google.');
      }
      final corpo = await _api.postJson('/auth/google', {'id_token': idToken})
          as Map<String, dynamic>;
      final token = corpo['access_token'] as String;
      _api.setToken(token);
      await _salvarToken(token);
      return _usuarioDe(corpo['usuario'] as Map<String, dynamic>);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Login com Google cancelado.');
      }
      throw const AuthException('Não foi possível entrar com o Google. Tente novamente.');
    } on AppException catch (e) {
      // A API responde 401 com "Conta Google não autorizada" (mensagem já pronta).
      throw AuthException(e.message);
    }
  }

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
      // Aceita {"nome", "email"} direto ou dentro de "usuario".
      final dados = (corpo['usuario'] ?? corpo) as Map<String, dynamic>;
      return _usuarioDe(dados);
    } catch (_) {
      // Token vencido/inválido, API fora do ar ou resposta inesperada:
      // começa do zero, pelo login.
      await signOut();
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    _api.setToken(null);
    try {
      await (await SharedPreferences.getInstance()).remove(_tokenKey);
    } catch (_) {
      // Sem armazenamento disponível: o token em memória já foi limpo.
    }
  }

  Future<void> _salvarToken(String token) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
    } catch (_) {
      // Se não der para salvar, o login vale só até o próximo F5.
    }
  }

  AuthUser _usuarioDe(Map<String, dynamic> dados) =>
      AuthUser(name: dados['nome'] as String, email: dados['email'] as String);
}
