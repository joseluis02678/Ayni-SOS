import 'package:uuid/uuid.dart';
import 'package:core/src/domain/entities/ai_analysis.dart';
import 'package:core/src/domain/entities/report.dart';
import 'package:core/src/domain/repositories/report_repository.dart';
import 'package:core/src/domain/repositories/sync_repository.dart';
import 'package:core/src/domain/value_objects/enums.dart';
import 'package:core/src/domain/value_objects/geo_point.dart';

/// Creates a local emergency report, persists it, and enqueues sync.
class CreateEmergencyReport {
  CreateEmergencyReport(this._reports, this._sync);

  final ReportRepository _reports;
  final SyncRepository _sync;
  final _uuid = const Uuid();

  Future<EmergencyReport> call({
    required EvidenceType evidenceType,
    required GeoPoint location,
    required String evidenceLocalPath,
    required String evidenceHash,
    EmergencyAnalysis? analysis,
  }) async {
    final id = _uuid.v4();
    final report = EmergencyReport(
      id: id,
      clientReportId: id,
      evidenceType: evidenceType,
      location: location,
      status: ReportStatus.pendingSync,
      priority: analysis?.priority ?? 3,
      createdAt: DateTime.now().toUtc(),
      disasterType: analysis?.disasterType,
      summary: analysis?.summary,
      evidenceLocalPath: evidenceLocalPath,
      evidenceHash: evidenceHash,
      analysis: analysis,
    );

    await _reports.saveLocal(report);
    await _sync.enqueue(report);
    return report;
  }
}
