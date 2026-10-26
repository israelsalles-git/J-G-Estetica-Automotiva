/// Erro com mensagem já pronta para ser exibida ao cliente.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Converte qualquer erro em texto seguro para a interface.
/// Erros inesperados (bugs, exceções de plataforma) não vazam para a tela.
String errorMessage(
  Object error, {
  String fallback = 'Algo deu errado. Tente novamente.',
}) =>
    error is AppException ? error.message : fallback;

/// Usada pelos repositórios padrão enquanto o backend não está ligado.
const backendNotConnected =
    AppException('O backend ainda não está conectado.');
