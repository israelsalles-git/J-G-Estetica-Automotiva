import '../models/service.dart';

/// CONTRATO: de onde vêm os serviços do catálogo.
/// Implementação real: `ApiCatalogRepository` (`/servicos`).
abstract class CatalogRepository {
  /// Serviços do catálogo. O site usa só os ativos; o painel pede
  /// [includeInactive] para ver também os pausados.
  Future<List<Service>> fetchServices({bool includeInactive = false});

  /// Cadastra um serviço (painel). [dados] já no formato da API (nome, categoria...).
  Future<Service> createService(Map<String, dynamic> dados);

  /// Altera um serviço (painel). Só os campos enviados mudam.
  Future<Service> updateService(String id, Map<String, dynamic> dados);

  /// Pausa o serviço (exclusão lógica: ele só deixa de aparecer no site).
  Future<void> deactivateService(String id);
}
