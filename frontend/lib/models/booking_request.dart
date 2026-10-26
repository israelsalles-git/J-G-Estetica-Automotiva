import 'service.dart';

/// Pedido de agendamento: o que o cliente escolheu.
///
/// Os dados do cliente (nome, telefone, e-mail, observações) são opcionais:
/// o formulário atual só pede dia e horário, mas o modelo já está pronto
/// caso o backend passe a exigir identificação.
class BookingRequest {
  final Service service;
  final String day;
  final String time;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? notes;

  const BookingRequest({
    required this.service,
    required this.day,
    required this.time,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.notes,
  });

  /// Corpo da requisição (POST) — só ids e valores escolhidos.
  Map<String, dynamic> toJson() => {
        'serviceId': service.id,
        'day': day,
        'time': time,
        if (customerName != null) 'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (notes != null) 'notes': notes,
      };
}

/// Resultado de um agendamento enviado com sucesso.
class BookingResult {
  /// Código/protocolo devolvido pelo backend (quando existir).
  final String? reference;

  /// Texto para mostrar ao cliente.
  final String message;

  const BookingResult({required this.message, this.reference});
}
