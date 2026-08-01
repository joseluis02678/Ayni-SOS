import 'package:core/core.dart';
import 'package:data/src/local/app_database.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._db);

  final AppDatabase _db;

  Map<String, dynamic> _toRow(EmergencyReport r) => {
        'id': r.id,
        'client_report_id': r.clientReportId,
        'server_id': r.serverId,
        'evidence_type': r.evidenceType.name,
        'latitude': r.location.latitude,
        'longitude': r.location.longitude,
        'accuracy_meters': r.location.accuracyMeters,
        'status': r.status.apiValue,
        'priority': r.priority,
        'created_at': r.createdAt.toIso8601String(),
        'updated_at': (r.updatedAt ?? r.createdAt).toIso8601String(),
        'disaster_type': r.disasterType?.apiValue,
        'summary': r.summary,
        'evidence_local_path': r.evidenceLocalPath,
        'evidence_hash': r.evidenceHash,
        'analysis': r.analysis?.toJson(),
        'sync_channel': r.syncChannel?.name,
        'assignee_count': r.assigneeCount,
      };

  EmergencyReport _fromRow(Map<String, dynamic> row) {
    ReportStatus parseStatus(String? v) {
      for (final s in ReportStatus.values) {
        if (s.apiValue == v || s.name == v) return s;
      }
      return ReportStatus.draft;
    }

    DisasterType? parseDisaster(String? v) {
      if (v == null) return null;
      return switch (v) {
        'flood' => DisasterType.flood,
        'el_nino_related' => DisasterType.elNinoRelated,
        'landslide' => DisasterType.landslide,
        _ => null,
      };
    }

    return EmergencyReport(
      id: row['id'] as String,
      clientReportId: row['client_report_id'] as String? ?? row['id'] as String,
      serverId: row['server_id'] as String? ?? row['id'] as String?,
      evidenceType: (row['evidence_type'] as String?) == 'audio'
          ? EvidenceType.audio
          : EvidenceType.photo,
      location: GeoPoint(
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        accuracyMeters: (row['accuracy_meters'] as num?)?.toDouble(),
      ),
      status: parseStatus(row['status'] as String?),
      priority: (row['priority'] as num?)?.toInt() ?? 3,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      disasterType: parseDisaster(row['disaster_type'] as String?),
      summary: row['summary'] as String?,
      evidenceLocalPath: row['evidence_local_path'] as String?,
      evidenceHash: row['evidence_hash'] as String?,
      analysis: row['analysis'] is Map<String, dynamic>
          ? EmergencyAnalysis.fromJson(row['analysis'] as Map<String, dynamic>)
          : null,
      syncChannel: row['sync_channel'] != null
          ? SyncChannel.values.byName(row['sync_channel'] as String)
          : null,
      assigneeCount: (row['assignee_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> saveLocal(EmergencyReport report) => _db.upsertReport(_toRow(report));

  @override
  Future<EmergencyReport?> getById(String id) async {
    final row = await _db.getReport(id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<EmergencyReport>> getHistory() async {
    final rows = await _db.allReports();
    rows.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<EmergencyReport>> getPendingSync() async {
    final rows = await _db.pendingReports();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> update(EmergencyReport report) => saveLocal(report);

  @override
  Future<EmergencyReport> upsertFromServer(Map<String, dynamic> json) async {
    final analysisJson = json['ai_analysis'] as Map<String, dynamic>?;
    final report = EmergencyReport(
      id: json['client_report_id'] as String? ?? json['id'] as String,
      clientReportId: json['client_report_id'] as String? ?? json['id'] as String,
      serverId: json['id'] as String?,
      evidenceType:
          (json['evidence_type'] as String?) == 'audio' ? EvidenceType.audio : EvidenceType.photo,
      location: GeoPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      ),
      status: ReportStatus.values.firstWhere(
        (s) => s.apiValue == json['status'],
        orElse: () => ReportStatus.received,
      ),
      priority: (json['priority'] as num?)?.toInt() ?? 3,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      disasterType: json['disaster_type'] != null
          ? DisasterType.values.firstWhere(
              (d) => d.apiValue == json['disaster_type'],
              orElse: () => DisasterType.landslide,
            )
          : null,
      summary: json['summary'] as String?,
      evidenceHash: json['evidence_hash'] as String?,
      analysis: analysisJson != null ? EmergencyAnalysis.fromJson(analysisJson) : null,
      syncChannel: json['sync_channel'] != null
          ? SyncChannel.values.byName(json['sync_channel'] as String)
          : null,
      assigneeCount: (json['assignee_count'] as num?)?.toInt() ?? 0,
    );
    await saveLocal(report);
    return report;
  }
}
