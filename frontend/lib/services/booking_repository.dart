import '../models/booking_request.dart';

abstract class BookingRepository {
  Future<Set<String>> fetchBusySlots(DateTime day);

  Future<BookingResult> submit(BookingRequest request);
}
