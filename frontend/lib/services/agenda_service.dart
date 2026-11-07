import 'package:frontend/models/agenda_appointment.dart';

/// Fonte dos atendimentos da agenda. As telas só conhecem esta interface,
/// que é entregue por `Provider<AgendaService>` (veja o main_admin.dart).
abstract class AgendaService {
  /// Atendimentos do dia [day], em qualquer ordem (a tela ordena por horário).
  Future<List<AgendaAppointment>> loadDay(DateTime day);
}
