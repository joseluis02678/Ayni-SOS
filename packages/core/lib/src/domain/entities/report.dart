import 'package:equatable/equatable.dart';
import 'package:core/src/domain/entities/ai_analysis.dart';
import 'package:core/src/domain/value_objects/enums.dart';
import 'package:core/src/domain/value_objects/geo_point.dart';

class EmergencyReport extends Equatable {
  const EmergencyReport({
    required this.id,
    required this.clientReportId,
    required this.evidenceType,
    required this.location,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.serverId,
    this.disasterType,
    this.summary,
    this.evidenceLocalPath,
    this.evidenceHash,
    this.analysis,
    this.syncChannel,
    this.assigneeCount = 0,
    this.updatedAt,
  });

  final String id;
  final String clientReportId;
  final String? serverId;
  final EvidenceType evidenceType;
  final GeoPoint location;
  final ReportStatus status;
  final int priority;
  final DateTime createdAt;
  final DisasterType? disasterType;
  final String? summary;
  final String? evidenceLocalPath;
  final String? evidenceHash;
  final EmergencyAnalysis? analysis;
  final SyncChannel? syncChannel;
  final int assigneeCount;
  final DateTime? updatedAt;

  EmergencyReport copyWith({
    ReportStatus? status,
    int? priority,
    String? summary,
    String? serverId,
    EmergencyAnalysis? analysis,
    SyncChannel? syncChannel,
    String? evidenceHash,
    int? assigneeCount,
    DisasterType? disasterType,
    DateTime? updatedAt,
  }) {
    return EmergencyReport(
      id: id,
      clientReportId: clientReportId,
      serverId: serverId ?? this.serverId,
      evidenceType: evidenceType,
      location: location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      disasterType: disasterType ?? this.disasterType,
      summary: summary ?? this.summary,
      evidenceLocalPath: evidenceLocalPath,
      evidenceHash: evidenceHash ?? this.evidenceHash,
      analysis: analysis ?? this.analysis,
      syncChannel: syncChannel ?? this.syncChannel,
      assigneeCount: assigneeCount ?? this.assigneeCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientReportId,
        serverId,
        evidenceType,
        location,
        status,
        priority,
        createdAt,
        disasterType,
        summary,
        evidenceHash,
        analysis,
        syncChannel,
        assigneeCount,
      ];
}
