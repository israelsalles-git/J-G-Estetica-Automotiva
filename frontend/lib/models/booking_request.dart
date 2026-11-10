import '../core/datas.dart';
import 'service.dart';

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
        'servico_id': int.parse(service.id),
      };
}

class BookingResult {
  final String? reference;

  final String message;

  const BookingResult({required this.message, this.reference});
}
