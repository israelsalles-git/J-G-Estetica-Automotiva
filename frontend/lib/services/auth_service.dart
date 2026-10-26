/// Usuário autenticado (dados mínimos; ampliar quando a API definir o formato).
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

/// Contrato de autenticação. A tela de login só conhece esta interface,
/// então trocar a implementação simulada pela real não exige mexer na tela.
abstract class AuthService {
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
}

/// Implementação SIMULADA, só para ver a tela funcionando.
/// Não valida nada de verdade e não é segura: substituir pela real
/// (API FastAPI e/ou Google) antes de qualquer uso fora de testes.
///
/// - E-mail: aceita qualquer e-mail válido com senha de 6+ caracteres.
///   Use a senha "errada" para ver a mensagem de erro.
/// - Google: sempre "funciona", devolvendo um usuário de exemplo.
class MockAuthService implements AuthService {
  const MockAuthService();

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (password == 'errada') {
      throw const AuthException('E-mail ou senha incorretos.');
    }
    return AuthUser(name: email.split('@').first, email: email);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const AuthUser(
      name: 'Usuário Google (simulado)',
      email: 'usuario@gmail.com',
    );
  }

  @override
  Future<void> signOut() async {}
}
