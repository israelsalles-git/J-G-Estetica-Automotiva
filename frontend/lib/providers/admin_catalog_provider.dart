import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/load_status.dart';
import '../models/service.dart';
import '../services/catalog_repository.dart';

class AdminCatalogProvider extends ChangeNotifier {
  AdminCatalogProvider({required CatalogRepository repository})
      : _repository = repository;

  final CatalogRepository _repository;

  LoadStatus _status = LoadStatus.idle;
  List<Service> _services = const [];
  String? _error;
  bool _saving = false;
  String? _actionError;

  LoadStatus get status => _status;
  List<Service> get services => _services;
  String? get error => _error;

  bool get isSaving => _saving;

  String? get actionError => _actionError;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _services = await _repository.fetchServices(includeInactive: true);
      _status = LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
      _error = errorMessage(e,
          fallback: 'Não foi possível carregar os serviços. Tente novamente.');
    }
    notifyListeners();
  }

  Future<bool> add(Map<String, dynamic> dados) =>
      _mutate(() => _repository.createService(dados));

  Future<bool> update(String id, Map<String, dynamic> dados) =>
      _mutate(() => _repository.updateService(id, dados));

  Future<bool> pause(String id) =>
      _mutate(() => _repository.deactivateService(id));

  Future<bool> reactivate(String id) =>
      _mutate(() => _repository.updateService(id, {'ativo': true}));

  Future<bool> _mutate(Future<void> Function() action) async {
    _saving = true;
    _actionError = null;
    notifyListeners();
    try {
      await action();
      try {
        _services = await _repository.fetchServices(includeInactive: true);
        _status = LoadStatus.success;
      } catch (_) {
      }
      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _saving = false;
      _actionError = errorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
