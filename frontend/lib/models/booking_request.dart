import '../core/datas.dart';
import 'service.dart';

/// Pedido de agendamento: o que o cliente escolheu no site.
///
/// [date] (dia) e [time] ("HH:mm") formam o início do atendimento, no horário de Brasília.
class BookingRequest {
  final Service service;
  final DateTime date;
  final String time;
  final String customerName;

  const BookingRequest({
    required this.service,
    required this.date,
    required this.time,
    required this.customerName,
  });

  /// Início do atendimento como data e hora completas.
  DateTime get inicio {
    final partes = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(partes[0]),
      int.parse(partes[1]),
    );
  }

  /// Corpo do `POST /agendamentos/publico`.
  Map<String, dynamic> toJson() => {
        'data': dataHoraIsoSemFuso(inicio),
        'nome_cliente': customerName,
        'servico_id': int.parse(service.id),
      };
}

/// Resultado de um agendamento enviado com sucesso.
class BookingResult {
  /// Número do agendamento devolvido pela API.
  final String? reference;

  /// Texto para mostrar ao cliente.
  final String message;

  const BookingResult({required this.message, this.reference});
}
