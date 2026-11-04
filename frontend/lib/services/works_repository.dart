import '../models/work.dart';

/// CONTRATO: trabalhos da galeria "Últimos Trabalhos".
/// `fetchWorks` alimenta o site; os demais métodos são para o painel admin.
/// Implementação real: `ApiWorksRepository`.
abstract class WorksRepository {
  Future<List<Work>> fetchWorks();
  Future<Work> createWork(WorkDraft draft);
  Future<Work> updateWork(Work work);
  Future<void> deleteWork(String id);
}
