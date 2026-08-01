import 'package:core/core.dart';

class CriticalPayload {
  CriticalPayload({
    required this.clientReportId,
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.disasterType,
    required this.evidenceHash,
  });

  final String clientReportId;
  final double latitude;
  final double longitude;
  final int priority;
  final DisasterType disasterType;
  final String evidenceHash;

  factory CriticalPayload.fromReport(EmergencyReport report) {
    return CriticalPayload(
      clientReportId: report.clientReportId,
      latitude: report.location.latitude,
      longitude: report.location.longitude,
      priority: report.priority,
      disasterType: report.disasterType ?? DisasterType.landslide,
      evidenceHash: report.evidenceHash ?? '',
    );
  }

  /// Compact SMS: AYNI|v1|{id8}|{lat}|{lon}|{pri}|{code}|{hash8}
  String toSmsMessage() {
    final short = clientReportId.replaceAll('-', '').substring(0, 8);
    final lat = (latitude * 10000).round();
    final lon = (longitude * 10000).round();
    final hash8 = evidenceHash.length >= 8
        ? evidenceHash.substring(0, 8)
        : evidenceHash.padRight(8, '0');
    return 'AYNI|v1|$short|$lat|$lon|$priority|${disasterType.smsCode}|$hash8';
  }

  Map<String, dynamic> toMeshJson() => {
        'type': 'critical',
        'client_report_id': clientReportId,
        'latitude': latitude,
        'longitude': longitude,
        'priority': priority,
        'disaster_type': disasterType.apiValue,
        'evidence_hash': evidenceHash,
      };
}

class FullPayload {
  FullPayload({
    required this.report,
  });

  final EmergencyReport report;

  factory FullPayload.fromReport(EmergencyReport report) => FullPayload(report: report);

  Map<String, dynamic> toApiJson() {
    final r = report;
    return {
      'client_report_id': r.clientReportId,
      'evidence_type': r.evidenceType.name,
      'latitude': r.location.latitude,
      'longitude': r.location.longitude,
      'accuracy_meters': r.location.accuracyMeters,
      'evidence_hash': r.evidenceHash,
      'disaster_type': r.disasterType?.apiValue,
      'priority': r.priority,
      'summary': r.summary,
      'ai_analysis': r.analysis?.toJson(),
      'sync_channel': 'http',
    };
  }
}
