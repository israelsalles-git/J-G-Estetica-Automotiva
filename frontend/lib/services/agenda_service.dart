import 'package:frontend/models/agenda_appointment.dart';

/// Fonte dos atendimentos da agenda. A tela só conhece esta interface.
///
/// Quando o endpoint do PNL-1 estiver pronto, crie outra classe (por exemplo
/// `ApiAgendaService`) que implemente [loadDay] chamando esse endpoint com o
/// filtro de um dia (algo como `?date=2026-11-02`) e converta o JSON em
/// [AgendaAppointment]. Depois é só passar essa classe no lugar da simulada,
/// sem mexer na tela.
abstract class AgendaService {
  /// Atendimentos do dia [day], em qualquer ordem (a tela ordena por horário).
  Future<List<AgendaAppointment>> loadDay(DateTime day);
}

class _DemoItem {
  const _DemoItem(
    this.hour,
    this.minute,
    this.minutes,
    this.vehicle,
    this.customer,
    this.service,
    this.box,
  );

  final int hour;
  final int minute;
  final int minutes;
  final String vehicle;
  final String customer;
  final String service;
  final int box;
}

const _demoDay = [
  _DemoItem(8, 0, 60, 'BMW 320i', 'Ana P.', 'Lavagem de Carro + Cera', 3),
  _DemoItem(9, 30, 60, 'Civic', 'Marcos T.', 'Lavagem de Carro', 4),
  _DemoItem(
    11,
    0,
    90,
    'Ducati Panigale V4',
    'Roberto M.',
    'Lavagem Detalhada de Moto',
    2,
  ),
  _DemoItem(14, 0, 60, 'Hilux', 'Paulo R.', 'Lavagem de Carro', 1),
  _DemoItem(15, 30, 60, 'CB 500', 'Joana L.', 'Lavagem de Moto + Cera', 2),
];

/// Implementação SIMULADA, só para ver a tela funcionando.
///
/// - Hoje: os atendimentos são montados em volta da hora atual, então sempre
///   há um concluído, um em andamento e alguns próximos (dá para ver o destaque).
/// - Outros dias: horários fixos. Dias de número par têm 5 atendimentos, os
///   ímpares têm 3, e dias múltiplos de 7 ficam vazios (para ver o estado vazio).
class MockAgendaService implements AgendaService {
  const MockAgendaService();

  @override
  Future<List<AgendaAppointment>> loadDay(DateTime day) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    return isToday ? _aroundNow(day, now) : _fixedDay(day);
  }

  List<AgendaAppointment> _aroundNow(DateTime day, DateTime now) {
    final base = DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute >= 30 ? 30 : 0,
    );

    AgendaAppointment make(
      String id,
      int offsetMinutes,
      int durationMinutes,
      String vehicle,
      String customer,
      String service,
      int box,
    ) {
      return AgendaAppointment(
        id: id,
        start: base.add(Duration(minutes: offsetMinutes)),
        duration: Duration(minutes: durationMinutes),
        vehicle: vehicle,
        customer: customer,
        service: service,
        box: box,
      );
    }

    final all = [
      make('hoje-1', -180, 60, 'BMW 320i', 'Ana P.',
          'Lavagem de Carro + Cera', 3),
      make('hoje-2', -90, 60, 'Civic', 'Marcos T.', 'Lavagem de Carro', 4),
      make('hoje-3', -15, 60, 'Ducati Panigale V4', 'Roberto M.',
          'Lavagem Detalhada de Moto', 2),
      make('hoje-4', 60, 90, 'Porsche 911 Carrera GTS', 'Lucas S.',
          'Lavagem de Carro + Cera', 1),
      make('hoje-5', 150, 60, 'Hilux', 'Paulo R.', 'Lavagem de Carro', 3),
    ];

    // Descarta o que cairia em outro dia (acontece em testes de madrugada).
    return all.where((a) => a.start.day == day.day).toList();
  }

  List<AgendaAppointment> _fixedDay(DateTime day) {
    if (day.day % 7 == 0) return const [];

    final count = day.day.isEven ? _demoDay.length : 3;
    final items = <AgendaAppointment>[
      for (var i = 0; i < count; i++)
        AgendaAppointment(
          id: '${day.year}-${day.month}-${day.day}-$i',
          start: DateTime(
            day.year,
            day.month,
            day.day,
            _demoDay[i].hour,
            _demoDay[i].minute,
          ),
          duration: Duration(minutes: _demoDay[i].minutes),
          vehicle: _demoDay[i].vehicle,
          customer: _demoDay[i].customer,
          service: _demoDay[i].service,
          box: _demoDay[i].box,
        ),
    ];

    // Devolvido de trás para frente de propósito: quem ordena é a tela.
    return items.reversed.toList();
  }
}
