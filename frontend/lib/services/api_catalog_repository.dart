import '../core/api_client.dart';
import '../models/service.dart';
import 'catalog_repository.dart';

/// Serviços vindos da API (`GET /servicos`, público).
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Service>> fetchServices() async {
    final lista = await _api.get('/servicos') as List;
    return [for (final j in lista) Service.fromJson(j as Map<String, dynamic>)];
  }
}
