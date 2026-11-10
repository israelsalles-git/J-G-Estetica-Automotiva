import 'package:frontend/models/agenda_appointment.dart';

abstract class AgendaService {
  Future<List<AgendaAppointment>> loadDay(DateTime day);
}
