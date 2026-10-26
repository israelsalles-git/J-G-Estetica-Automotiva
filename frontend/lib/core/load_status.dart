/// Estado de qualquer operação assíncrona (carregar lista, enviar formulário…).
///
/// - [idle]: ainda não começou
/// - [loading]: em andamento
/// - [success]: terminou bem
/// - [error]: falhou (a mensagem fica no provider que usa o status)
enum LoadStatus { idle, loading, success, error }
