import '../core/app_exception.dart';
import '../models/work.dart';

/// CONTRATO: trabalhos da galeria "Últimos Trabalhos".
/// `fetchWorks` alimenta o site; os demais métodos são para o painel admin.
abstract class WorksRepository {
  Future<List<Work>> fetchWorks();
  Future<Work> createWork(WorkDraft draft);
  Future<Work> updateWork(Work work);
  Future<void> deleteWork(String id);
}

/// Padrão enquanto não há backend.
class NotConnectedWorksRepository implements WorksRepository {
  const NotConnectedWorksRepository();

  @override
  Future<List<Work>> fetchWorks() async => throw backendNotConnected;

  @override
  Future<Work> createWork(WorkDraft draft) async => throw backendNotConnected;

  @override
  Future<Work> updateWork(Work work) async => throw backendNotConnected;

  @override
  Future<void> deleteWork(String id) async => throw backendNotConnected;
}
