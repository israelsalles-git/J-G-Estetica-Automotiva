import '../core/app_exception.dart';
import '../models/booking_request.dart';

/// CONTRATO: disponibilidade e envio do agendamento.
/// Quem decide o que é "ocupado" e o que acontece ao confirmar é o backend.
abstract class BookingRepository {
  /// Horários ocupados no [day] (ex.: {'10:00', '13:00'}).
  Future<Set<String>> fetchBusySlots(String day);

  /// Envia o pedido. Devolva o texto a mostrar ao cliente em [BookingResult.message];
  /// em caso de recusa, lance `AppException('mensagem para o cliente')`.
  Future<BookingResult> submit(BookingRequest request);
}

/// Padrão enquanto não há backend: nada é enviado.
class NotConnectedBookingRepository implements BookingRepository {
  const NotConnectedBookingRepository();

  @override
  Future<Set<String>> fetchBusySlots(String day) async => throw backendNotConnected;

  @override
  Future<BookingResult> submit(BookingRequest request) async =>
      throw backendNotConnected;
}
