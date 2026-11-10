/// Situação de um atendimento em relação ao horário atual.
enum AgendaStatus { concluido, emAndamento, agendado }

class AgendaAppointment {
  const AgendaAppointment({
    required this.id,
    required this.start,
    required this.duration,
    required this.customer,
    required this.service,
  });

  final String id;
  final DateTime start;
  final Duration duration;
  final String customer;
  final String service;

  DateTime get end => start.add(duration);

  AgendaStatus statusAt(DateTime now) {
    if (now.isBefore(start)) return AgendaStatus.agendado;
    if (now.isBefore(end)) return AgendaStatus.emAndamento;
    return AgendaStatus.concluido;
  }
}
