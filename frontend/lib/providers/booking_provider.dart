   import 'package:flutter/foundation.dart';
import '../models/service.dart';
import '../services/catalog_service.dart';
import '../services/whatsapp_service.dart';

class BookingProvider extends ChangeNotifier {
  int _serviceIndex = 0;
  String _day = CatalogService.days.first;
  String? _time;

  int get serviceIndex => _serviceIndex;
  Service get service => CatalogService.services[_serviceIndex];
  String get day => _day;
  String? get time => _time;

  bool get isValid => _time != null;

  void selectService(int index) {
    _serviceIndex = index;
    notifyListeners();
  }

  void selectDay(String day) {
    _day = day;
    notifyListeners();
  }

  void selectTime(String time) {
    _time = time;
    notifyListeners();
  }

  String buildMessage() {
    final s = service;
    return 'Olá! Quero agendar:\n'
        'Serviço: ${s.name}\n'
        'Dia: $_day\n'
        'Horário: $_time\n'
        'Valor: ${s.priceLabel}';
  }

  Future<void> confirmByWhatsapp() =>
      WhatsappService.open(message: buildMessage());
}
