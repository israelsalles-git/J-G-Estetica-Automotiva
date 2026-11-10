import '../core/api_client.dart';
import '../core/datas.dart';
import '../models/work.dart';
import 'works_repository.dart';

class ApiWorksRepository implements WorksRepository {
  ApiWorksRepository(this._api);

  final ApiClient _api;

  Work _doJson(dynamic json) =>
      Work.fromJson(json as Map<String, dynamic>, baseUrl: _api.baseUrl);

  @override
  Future<List<Work>> fetchWorks() async {
    final lista = await _api.get('/trabalhos') as List;
    return [for (final j in lista) _doJson(j)];
  }

  @override
  Future<Work> createWork(WorkDraft draft) async {
    final json = await _api.postArquivo(
      '/trabalhos',
      campos: draft.toFields(),
      campoArquivo: 'imagem',
      bytes: draft.imageBytes,
      nomeArquivo: draft.imageFileName,
    );
    return _doJson(json);
  }

  @override
  Future<Work> updateWork(Work work) async {
    final json = await _api.putJson('/trabalhos/${work.id}', {
      'titulo': work.title,
      'descricao': work.description,
      'categoria': work.category,
      'data': work.date == null ? null : dataIso(work.date!),
    });
    return _doJson(json);
  }

  @override
  Future<void> deleteWork(String id) => _api.delete('/trabalhos/$id');
}
