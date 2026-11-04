import '../models/service.dart';

/// CONTRATO: de onde vêm os serviços do catálogo.
/// Implementação real: `ApiCatalogRepository` (GET /servicos).
abstract class CatalogRepository {
  Future<List<Service>> fetchServices();
}
