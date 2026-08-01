import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:sync_engine/src/payloads.dart';
import 'package:sync_engine/src/sync_transport.dart';

class HttpTransport implements SyncTransport {
  HttpTransport(this._dio, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Dio _dio;
  final Connectivity _connectivity;

  @override
  SyncChannel get channel => SyncChannel.http;

  @override
  Future<TransportCapability> probe() async {
    final results = await _connectivity.checkConnectivity();
    final hasNet = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other);
    if (!hasNet) {
      return const TransportCapability(
        canSendCritical: false,
        canSendFull: false,
        channel: SyncChannel.http,
        description: 'No internet',
      );
    }
    return const TransportCapability(
      canSendCritical: true,
      canSendFull: true,
      channel: SyncChannel.http,
      description: 'Internet available',
    );
  }

  @override
  Future<SyncResult> sendCriticalPayload(CriticalPayload payload) async {
    // Critical over HTTP still uses full create endpoint with minimal fields
    return sendFullPayload(
      FullPayload(
        report: EmergencyReport(
          id: payload.clientReportId,
          clientReportId: payload.clientReportId,
          evidenceType: EvidenceType.photo,
          location: GeoPoint(latitude: payload.latitude, longitude: payload.longitude),
          status: ReportStatus.pendingSync,
          priority: payload.priority,
          createdAt: DateTime.now().toUtc(),
          disasterType: payload.disasterType,
          evidenceHash: payload.evidenceHash,
        ),
      ),
    );
  }

  @override
  Future<SyncResult> sendFullPayload(FullPayload payload) async {
    try {
      final res = await _dio.post('/api/v1/reports', data: payload.toApiJson());
      final data = res.data as Map<String, dynamic>;
      return SyncResult(
        success: true,
        channel: SyncChannel.http,
        serverId: data['id'] as String?,
      );
    } catch (e) {
      return SyncResult.fail(SyncChannel.http, e.toString());
    }
  }
}
