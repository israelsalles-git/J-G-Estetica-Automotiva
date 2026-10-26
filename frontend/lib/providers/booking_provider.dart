import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/business_config.dart';
import '../core/load_status.dart';
import '../core/validators.dart';
import '../models/booking_request.dart';
import '../models/service.dart';
import '../services/booking_repository.dart';
import 'catalog_provider.dart';

/// Estado do agendamento: serviço, dia, horário, disponibilidade,
/// validação dos campos e envio (loading/sucesso/erro).
class BookingProvider extends ChangeNotifier {
  final CatalogProvider _catalog;
  final BookingRepository _repository;

  BookingProvider({
    required CatalogProvider catalog,
    required BookingRepository repository,
  })  : _catalog = catalog,
        _repository = repository {
    // Quando o catálogo carrega/muda, o resumo precisa se redesenhar.
    _catalog.addListener(notifyListeners);
    _loadAvailability();
  }

  @override
  void dispose() {
    _catalog.removeListener(notifyListeners);
    super.dispose();
  }

  // ---- escolhas do cliente ----
  Service? _service; // null = ainda não escolheu → usa o primeiro do catálogo
  String _day = BusinessConfig.days.first;
  String? _time;

  /// Serviço escolhido (ou o primeiro do catálogo, enquanto nada foi escolhido).
  Service? get service =>
      _service ?? (_catalog.services.isEmpty ? null : _catalog.services.first);
  String get day => _day;
  String? get time => _time;

  // ---- disponibilidade ----
  Set<String> _busySlots = const {};
  LoadStatus _slotsStatus = LoadStatus.idle;
  String? _slotsError;

  Set<String> get busySlots => _busySlots;
  LoadStatus get slotsStatus => _slotsStatus;
  String? get slotsError => _slotsError;

  // ---- validação ----
  Map<String, String> _errors = const {};

  /// Erro de um campo ('service', 'day' ou 'time'), ou null.
  String? errorFor(String field) => _errors[field];

  // ---- envio ----
  LoadStatus _submitStatus = LoadStatus.idle;
  String? _submitError;
  BookingResult? _result;

  LoadStatus get submitStatus => _submitStatus;
  bool get isSubmitting => _submitStatus == LoadStatus.loading;
  String? get submitError => _submitError;
  String? get resultMessage => _result?.message;

  /// Primeira mensagem de erro de validação (para mostrar num aviso).
  String? get firstError => _errors.values.isEmpty ? null : _errors.values.first;

  void selectService(Service service) {
    _service = service;
    _afterEdit('service');
  }

  void selectDay(String day) {
    if (day == _day) return;
    _day = day;
    _afterEdit('day');
    _loadAvailability();
  }

  void selectTime(String time) {
    _time = time;
    _afterEdit('time');
  }

  void _afterEdit(String field) {
    if (_errors.containsKey(field)) {
      _errors = Map.of(_errors)..remove(field);
    }
    _submitStatus = LoadStatus.idle;
    _submitError = null;
    notifyListeners();
  }

  Future<void> reloadAvailability() => _loadAvailability();

  Future<void> _loadAvailability() async {
    final requestedDay = _day;
    _slotsStatus = LoadStatus.loading;
    _slotsError = null;
    notifyListeners();
    try {
      final busy = await _repository.fetchBusySlots(requestedDay);
      if (requestedDay != _day) return; // o cliente já trocou de dia
      _busySlots = busy;
      if (_time != null && busy.contains(_time)) _time = null;
      _slotsStatus = LoadStatus.success;
    } catch (e) {
      if (requestedDay != _day) return;
      _busySlots = const {};
      _slotsStatus = LoadStatus.error;
      _slotsError = errorMessage(e,
          fallback: 'Não foi possível verificar a disponibilidade.');
    }
    notifyListeners();
  }

  /// Valida as escolhas. Guarda os erros por campo e retorna true se está tudo certo.
  bool validate() {
    final errors = <String, String>{};

    final serviceError =
        Validators.choice(service, 'Escolha um serviço no catálogo.');
    if (serviceError != null) errors['service'] = serviceError;

    final dayError = Validators.choice(_day, 'Escolha o dia do atendimento.');
    if (dayError != null) errors['day'] = dayError;

    final timeError = Validators.choice(_time, 'Escolha o horário desejado.');
    if (timeError != null) {
      errors['time'] = timeError;
    } else if (_busySlots.contains(_time)) {
      errors['time'] = 'Esse horário não está mais disponível.';
    }

    _errors = errors;
    notifyListeners();
    return errors.isEmpty;
  }

  /// Valida e envia o agendamento. Retorna true se foi enviado com sucesso.
  Future<bool> submit() async {
    if (isSubmitting) return false;
    if (!validate()) return false;

    _submitStatus = LoadStatus.loading;
    _submitError = null;
    notifyListeners();
    try {
      _result = await _repository.submit(
        BookingRequest(service: service!, day: _day, time: _time!),
      );
      _submitStatus = LoadStatus.success;
    } catch (e) {
      _submitStatus = LoadStatus.error;
      _submitError = errorMessage(e,
          fallback: 'Não foi possível enviar o agendamento. Tente novamente.');
    }
    notifyListeners();
    return _submitStatus == LoadStatus.success;
  }
}
