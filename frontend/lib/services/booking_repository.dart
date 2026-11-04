import '../models/booking_request.dart';

/// CONTRATO: disponibilidade e envio do agendamento.
/// Quem decide o que é "ocupado" e aceita o pedido é o backend.
/// Implementação real: `ApiBookingRepository`.
abstract class BookingRepository {
  /// Horários "HH:mm" que começam dentro de algum atendimento já marcado no [day].
  Future<Set<String>> fetchBusySlots(DateTime day);

  /// Envia o pedido. Devolve o texto a mostrar ao cliente em [BookingResult.message].
  /// Em caso de recusa, lança `AppException('mensagem para o cliente')`.
  Future<BookingResult> submit(BookingRequest request);
}
