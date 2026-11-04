import '../core/api_client.dart';
import '../core/app_exception.dart';

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
  Future<void> signOut();
}

/// Login do painel contra a API (`POST /auth/login`).
///
/// O token JWT fica no [ApiClient], que o envia nas próximas requisições.
class ApiAuthService implements AuthService {
  ApiAuthService(this._api);

  final ApiClient _api;

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final corpo = await _api.postJson('/auth/login', {'email': email, 'senha': password})
          as Map<String, dynamic>;
      _api.setToken(corpo['access_token'] as String);
      final usuario = corpo['usuario'] as Map<String, dynamic>;
      return AuthUser(name: usuario['nome'] as String, email: usuario['email'] as String);
    } on AppException catch (e) {
      // A API responde 401 com "E-mail ou senha incorretos" (mensagem já pronta).
      throw AuthException(e.message);
    }
  }

  /// A API ainda não tem login com Google.
  @override
  Future<AuthUser> signInWithGoogle() async =>
      throw const AuthException('Entrar com o Google ainda não está disponível.');

  @override
  Future<void> signOut() async => _api.setToken(null);
}
