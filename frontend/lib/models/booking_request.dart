import '../core/datas.dart';
import 'service.dart';

class BookingRequest {
  final Service service;
  final DateTime date;
  final String time;
  final String customerName;

  /// Só dígitos: DDD + número (10 ou 11), como a API espera.
  final String customerPhone;

  const BookingRequest({
    required this.service,
    required this.date,
    required this.time,
    required this.customerName,
    required this.customerPhone,
  });

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

  Map<String, dynamic> toJson() => {
        'data': dataHoraIsoSemFuso(inicio),
        'nome_cliente': customerName,
        'telefone': customerPhone,
        'servico_id': int.parse(service.id),
      };
}

class BookingResult {
  final String? reference;

  final String message;

  const BookingResult({required this.message, this.reference});
}
