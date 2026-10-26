import '../core/app_exception.dart';
import '../models/service.dart';

/// CONTRATO: de onde vêm os serviços do catálogo.
/// O backend implementa esta classe; a interface só chama `fetchServices()`.
abstract class CatalogRepository {
  Future<List<Service>> fetchServices();
}

/// Padrão enquanto não há backend: não entrega nada e a tela mostra o erro.
class NotConnectedCatalogRepository implements CatalogRepository {
  const NotConnectedCatalogRepository();

  @override
  Future<List<Service>> fetchServices() async => throw backendNotConnected;
}
