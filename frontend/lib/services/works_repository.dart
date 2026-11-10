import '../models/work.dart';

abstract class WorksRepository {
  Future<List<Work>> fetchWorks();
  Future<Work> createWork(WorkDraft draft);
  Future<Work> updateWork(Work work);
  Future<void> deleteWork(String id);
}
