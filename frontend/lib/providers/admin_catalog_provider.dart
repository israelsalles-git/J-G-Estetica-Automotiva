import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/load_status.dart';
import '../models/service.dart';
import '../services/catalog_repository.dart';

/// Catálogo do PAINEL: todos os serviços (inclusive os pausados) e as ações
/// de criar, editar, pausar e reativar. Separado do `CatalogProvider` do site,
/// que só guarda os serviços ativos.
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

  /// Há um cadastro/edição/pausa em andamento.
  bool get isSaving => _saving;

  /// Erro da última ação (null se deu certo).
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

  /// "Pausar": exclusão lógica (`DELETE /servicos/{id}`).
  Future<bool> pause(String id) =>
      _mutate(() => _repository.deactivateService(id));

  /// "Reativar": `PUT /servicos/{id}` com `{"ativo": true}`.
  Future<bool> reactivate(String id) =>
      _mutate(() => _repository.updateService(id, {'ativo': true}));

  /// Roda a ação e, se der certo, recarrega a lista para refletir o banco.
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
        // A ação deu certo; se só a releitura falhou, o botão "Tentar novamente" resolve.
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
