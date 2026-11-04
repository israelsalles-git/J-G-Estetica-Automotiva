import '../core/api_client.dart';
import '../core/business_config.dart';
import '../core/datas.dart';
import '../models/booking_request.dart';
import 'booking_repository.dart';

/// Disponibilidade e envio do agendamento pela API
/// (`GET /agendamentos/ocupados` e `POST /agendamentos/publico`, ambos públicos).
class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._api);

  final ApiClient _api;

  // A API devolve datas com o fuso de Brasília (-03:00), que não muda desde 2019.
  // Subtraindo as 3 horas, o DateTime passa a representar o relógio de Brasília.
  static DateTime _relogioDeBrasilia(String iso) =>
      DateTime.parse(iso).toUtc().subtract(const Duration(hours: 3));

  @override
  Future<Set<String>> fetchBusySlots(DateTime day) async {
    final dia = dataIso(day);
    final lista = await _api.get('/agendamentos/ocupados', query: {
      'data_inicio': '${dia}T00:00:00-03:00',
      'data_fim': '${dia}T23:59:59-03:00',
    }) as List;

    final periodos = [
      for (final p in lista)
        (
          inicio: _relogioDeBrasilia(p['inicio'] as String),
          fim: _relogioDeBrasilia(p['fim'] as String),
        ),
    ];

    return {
      for (final horario in BusinessConfig.timeSlots)
        if (_ocupado(day, horario, periodos)) horario,
    };
  }

  static bool _ocupado(
    DateTime day,
    String horario,
    List<({DateTime inicio, DateTime fim})> periodos,
  ) {
    final partes = horario.split(':');
    final inicioDoHorario = DateTime.utc(
      day.year,
      day.month,
      day.day,
      int.parse(partes[0]),
      int.parse(partes[1]),
    );
    return periodos.any((p) =>
        !inicioDoHorario.isBefore(p.inicio) && inicioDoHorario.isBefore(p.fim));
  }

  @override
  Future<BookingResult> submit(BookingRequest request) async {
    final corpo = await _api.postJson('/agendamentos/publico', request.toJson())
        as Map<String, dynamic>;
    return BookingResult(
      reference: corpo['id'].toString(),
      message:
          'Agendamento confirmado para ${dataBr(request.date)} às ${request.time}. Até lá!',
    );
  }
}
