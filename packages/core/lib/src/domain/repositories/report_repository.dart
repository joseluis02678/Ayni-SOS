import 'package:core/src/domain/entities/report.dart';

abstract class ReportRepository {
  Future<void> saveLocal(EmergencyReport report);

  Future<EmergencyReport?> getById(String id);

  Future<List<EmergencyReport>> getHistory();

  Future<List<EmergencyReport>> getPendingSync();

  Future<void> update(EmergencyReport report);

  Future<EmergencyReport> upsertFromServer(Map<String, dynamic> json);
}
