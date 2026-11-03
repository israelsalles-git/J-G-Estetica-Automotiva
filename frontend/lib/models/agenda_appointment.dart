/// Situação de um atendimento em relação ao horário atual.
enum AgendaStatus { concluido, emAndamento, agendado }

/// Um atendimento da agenda: um veículo, num box, num horário.
class AgendaAppointment {
  const AgendaAppointment({
    required this.id,
    required this.start,
    required this.duration,
    required this.vehicle,
    required this.customer,
    required this.service,
    required this.box,
  });

  final String id;
  final DateTime start;
  final Duration duration;
  final String vehicle;
  final String customer;
  final String service;
  final int box;

  DateTime get end => start.add(duration);

  /// Calculado a partir do horário [now]:
  /// antes do início = agendado, entre início e fim = em andamento,
  /// depois do fim = concluído. Isso vale para qualquer dia: um dia passado
  /// fica todo concluído e um dia futuro fica todo agendado.
  AgendaStatus statusAt(DateTime now) {
    if (now.isBefore(start)) return AgendaStatus.agendado;
    if (now.isBefore(end)) return AgendaStatus.emAndamento;
    return AgendaStatus.concluido;
  }
}
