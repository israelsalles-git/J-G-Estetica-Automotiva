import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/agenda_appointment.dart';
import 'package:frontend/services/agenda_service.dart';

/// Agenda do painel contra a API: `GET /agendamentos?data_inicio=...&data_fim=...`
/// (rota do painel, exige o token que o [ApiClient] já guarda depois do login).
class ApiAgendaService implements AgendaService {
  ApiAgendaService(this._api);

  final ApiClient _api;

  @override
  Future<List<AgendaAppointment>> loadDay(DateTime day) async {
    // Datas SEM fuso: a API as interpreta no horário da empresa.
    final inicio = DateTime(day.year, day.month, day.day);
    final fim = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final corpo = await _api.get('/agendamentos', query: {
      'data_inicio': inicio.toIso8601String(),
      'data_fim': fim.toIso8601String(),
    });

    return [
      for (final item in corpo as List)
        _paraAgendamento(item as Map<String, dynamic>),
    ];
  }

  AgendaAppointment _paraAgendamento(Map<String, dynamic> json) {
    final servico = json['servico'] as Map<String, dynamic>;
    final minutos = (servico['duracao_min'] as num?)?.toInt() ?? 60;
    return AgendaAppointment(
      id: '${json['id']}',
      start: _horarioDaEmpresa(json['data'] as String),
      duration: Duration(minutes: minutos),
      customer: json['nome_cliente'] as String,
      service: servico['nome'] as String,
    );
  }

  /// A API manda a data já no fuso da empresa (ex.: 2026-11-08T09:00:00-03:00).
  /// Pegamos só "data e hora do relógio" para a tela mostrar o mesmo horário
  /// em qualquer computador, mesmo com o fuso do navegador diferente.
  DateTime _horarioDaEmpresa(String iso) => DateTime.parse(iso.substring(0, 19));
}
