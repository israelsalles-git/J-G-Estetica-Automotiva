import '../core/api_client.dart';
import '../models/service.dart';
import 'catalog_repository.dart';

/// Serviços pela API: leitura pública (`GET /servicos`) e cadastro/edição/pausa
/// do painel admin (exigem o token do login).
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Service>> fetchServices({bool includeInactive = false}) async {
    final lista = await _api.get(
      '/servicos',
      query: includeInactive ? {'incluir_inativos': 'true'} : null,
    ) as List;
    return [for (final j in lista) Service.fromJson(j as Map<String, dynamic>)];
  }

  @override
  Future<Service> createService(Map<String, dynamic> dados) async =>
      Service.fromJson(
        await _api.postJson('/servicos', dados) as Map<String, dynamic>,
      );

  @override
  Future<Service> updateService(String id, Map<String, dynamic> dados) async =>
      Service.fromJson(
        await _api.putJson('/servicos/$id', dados) as Map<String, dynamic>,
      );

  @override
  Future<void> deactivateService(String id) => _api.delete('/servicos/$id');
}
