import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/load_status.dart';
import '../models/service.dart';
import '../services/catalog_repository.dart';

/// Guarda a lista de serviços e o estado do carregamento (loading/sucesso/erro).
class CatalogProvider extends ChangeNotifier {
  final CatalogRepository _repository;

  CatalogProvider({required CatalogRepository repository})
      : _repository = repository;

  LoadStatus _status = LoadStatus.idle;
  List<Service> _services = const [];
  String? _error;

  LoadStatus get status => _status;
  List<Service> get services => _services;
  String? get error => _error;

  /// Categorias na ordem em que aparecem no catálogo (ex.: Carro, Moto).
  List<String> get categories {
    final seen = <String>[];
    for (final s in _services) {
      if (!seen.contains(s.category)) seen.add(s.category);
    }
    return seen;
  }

  List<Service> byCategory(String category) =>
      _services.where((s) => s.category == category).toList();

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _services = await _repository.fetchServices();
      _status = LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
      _error = errorMessage(e,
          fallback: 'Não foi possível carregar os serviços. Tente novamente.');
    }
    notifyListeners();
  }
}
