enum UserRole { citizen, rescuer, admin }

enum EvidenceType { audio, photo }

enum DisasterType { landslide, flood, elNinoRelated }

enum ReportStatus {
  draft,
  analyzing,
  pendingSync,
  queued,
  received,
  assigned,
  inProgress,
  resolved,
  cancelled,
}

enum RiskLevel { low, medium, high, critical }

enum AssignmentStatus { accepted, enRoute, onScene, completed, withdrawn }

enum SyncChannel { http, sms, mesh }

extension DisasterTypeApi on DisasterType {
  String get apiValue => switch (this) {
        DisasterType.landslide => 'landslide',
        DisasterType.flood => 'flood',
        DisasterType.elNinoRelated => 'el_nino_related',
      };

  String get smsCode => switch (this) {
        DisasterType.landslide => 'L',
        DisasterType.flood => 'F',
        DisasterType.elNinoRelated => 'N',
      };
}

extension ReportStatusApi on ReportStatus {
  String get apiValue => switch (this) {
        ReportStatus.draft => 'draft',
        ReportStatus.analyzing => 'analyzing',
        ReportStatus.pendingSync => 'pending_sync',
        ReportStatus.queued => 'queued',
        ReportStatus.received => 'received',
        ReportStatus.assigned => 'assigned',
        ReportStatus.inProgress => 'in_progress',
        ReportStatus.resolved => 'resolved',
        ReportStatus.cancelled => 'cancelled',
      };

  String get labelEs => switch (this) {
        ReportStatus.draft => 'Borrador',
        ReportStatus.analyzing => 'Analizando',
        ReportStatus.pendingSync => 'Pendiente de envío',
        ReportStatus.queued => 'En cola',
        ReportStatus.received => 'Recibido',
        ReportStatus.assigned => 'Asignado',
        ReportStatus.inProgress => 'En progreso',
        ReportStatus.resolved => 'Resuelto',
        ReportStatus.cancelled => 'Cancelado',
      };
}
