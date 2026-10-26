import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/load_status.dart';
import '../models/work.dart';
import '../services/works_repository.dart';

/// Estado da galeria de trabalhos: lista + carregamento + adicionar/editar/remover.
class WorksProvider extends ChangeNotifier {
  final WorksRepository _repository;

  WorksProvider({required WorksRepository repository})
      : _repository = repository;

  LoadStatus _status = LoadStatus.idle;
  List<Work> _works = const [];
  String? _error;
  bool _saving = false;
  String? _actionError;

  LoadStatus get status => _status;
  List<Work> get works => _works;
  String? get error => _error;

  /// Há um cadastro/edição/remoção em andamento.
  bool get isSaving => _saving;

  /// Erro da última ação de cadastro/edição/remoção (null se deu certo).
  String? get actionError => _actionError;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _works = await _repository.fetchWorks();
      _status = LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
      _error = errorMessage(e,
          fallback: 'Não foi possível carregar os trabalhos. Tente novamente.');
    }
    notifyListeners();
  }

  /// Cadastra um trabalho novo; o mais recente aparece primeiro.
  Future<bool> add(WorkDraft draft) => _mutate(() async {
        final created = await _repository.createWork(draft);
        _works = [created, ..._works];
      });

  Future<bool> update(Work work) => _mutate(() async {
        final saved = await _repository.updateWork(work);
        _works = [for (final w in _works) w.id == saved.id ? saved : w];
      });

  Future<bool> remove(String id) => _mutate(() async {
        await _repository.deleteWork(id);
        _works = _works.where((w) => w.id != id).toList();
      });

  Future<bool> _mutate(Future<void> Function() action) async {
    _saving = true;
    _actionError = null;
    notifyListeners();
    try {
      await action();
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
