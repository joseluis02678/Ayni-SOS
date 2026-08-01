import 'package:core/core.dart';
import 'package:cross_file/cross_file.dart';
import 'package:data/src/local/app_database.dart';
import 'package:data/src/remote/api_client.dart';
import 'package:dio/dio.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:uuid/uuid.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._db, this._api, this._router, this._reports);

  final AppDatabase _db;
  final ApiClient _api;
  final TransportRouter _router;
  final ReportRepository _reports;
  final _uuid = const Uuid();

  @override
  Future<void> enqueue(EmergencyReport report) async {
    await _db.enqueueOutbox({
      'id': _uuid.v4(),
      'operation': 'create_report',
      'client_id': report.clientReportId,
      'report_id': report.id,
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
    });
  }

  @override
  Future<void> processOutbox() async {
    final pending = await _db.outboxPending();
    for (final item in pending) {
      final report = await _reports.getById(item['report_id'] as String);
      if (report == null) {
        await _db.markOutboxDone(item['id'] as String);
        continue;
      }

      final critical = CriticalPayload.fromReport(report);
      final full = FullPayload.fromReport(report);

      final capability = await _router.probeBest();
      final SyncResult result;
      if (capability.canSendFull) {
        result = await _router.sendFull(full);
      } else if (capability.canSendCritical) {
        result = await _router.sendCritical(critical);
      } else {
        result = await _router.sendCritical(critical);
      }

      if (result.success) {
        final updated = report.copyWith(
          status: result.channel == SyncChannel.http
              ? ReportStatus.received
              : ReportStatus.queued,
          syncChannel: result.channel,
          serverId: result.serverId ?? report.serverId,
        );
        await _reports.update(updated);
        await _db.markOutboxDone(item['id'] as String);

        if (result.channel == SyncChannel.http &&
            report.evidenceLocalPath != null &&
            updated.serverId != null) {
          await _uploadMedia(updated);
        }
      }
    }
  }

  Future<void> _uploadMedia(EmergencyReport report) async {
    if (report.evidenceLocalPath == null || report.serverId == null) return;
    try {
      final path = report.evidenceLocalPath!;
      final name = path.split(RegExp(r'[\\/]')).last;
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty) return;
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: name),
        'sha256': report.evidenceHash ?? '',
      });
      await _api.dio.post(
        '/api/v1/sync/media/${report.serverId}',
        data: form,
      );
    } catch (_) {
      // Best-effort: leave file for a later sync cycle.
    }
  }

  @override
  Future<void> pullRemote({DateTime? since}) async {
    final query = <String, dynamic>{};
    if (since != null) query['since'] = since.toUtc().toIso8601String();
    final res = await _api.dio.get('/api/v1/sync/pull', queryParameters: query);
    final data = res.data as Map<String, dynamic>;
    final reports = (data['reports'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final r in reports) {
      await _reports.upsertFromServer(r);
    }
    await _db.cacheIncidents(reports);
  }
}
