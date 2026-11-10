import '../models/service.dart';

abstract class CatalogRepository {
  Future<List<Service>> fetchServices({bool includeInactive = false});

  Future<Service> createService(Map<String, dynamic> dados);

  Future<Service> updateService(String id, Map<String, dynamic> dados);

  Future<void> deactivateService(String id);
}
