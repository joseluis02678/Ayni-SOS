import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:sync_engine/src/payloads.dart';
import 'package:sync_engine/src/sync_transport.dart';

/// Scenario 2: cellular-only critical path via SMS gateway.
///
/// On Android prototype, [onSendSms] can use platform SMS.
/// Otherwise posts to `/api/v1/sync/sms-inbound` when a gateway relay is reachable.
class SmsTransport implements SyncTransport {
  SmsTransport(
    this._dio, {
    this.smsInboundSecret = 'ayni-sms-inbound-secret',
    this.onSendSms,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Dio _dio;
  final String smsInboundSecret;
  final Future<bool> Function(String phone, String message)? onSendSms;
  final Connectivity _connectivity;

  /// Gateway phone number / virtual number for prototype.
  String gatewayPhone = '+51000000000';

  @override
  SyncChannel get channel => SyncChannel.sms;

  @override
  Future<TransportCapability> probe() async {
    final results = await _connectivity.checkConnectivity();
    final hasInternet = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
    final hasMobile = results.contains(ConnectivityResult.mobile);

    // Prefer SMS only when mobile is available but full internet is not.
    if (hasMobile && !hasInternet) {
      return const TransportCapability(
        canSendCritical: true,
        canSendFull: false,
        channel: SyncChannel.sms,
        description: 'Cellular — SMS critical path',
      );
    }
    // Also available as fallback when onSendSms is wired
    if (onSendSms != null && hasMobile) {
      return const TransportCapability(
        canSendCritical: true,
        canSendFull: false,
        channel: SyncChannel.sms,
        description: 'SMS available',
      );
    }
    return const TransportCapability(
      canSendCritical: false,
      canSendFull: false,
      channel: SyncChannel.sms,
      description: 'SMS not available',
    );
  }

  @override
  Future<SyncResult> sendCriticalPayload(CriticalPayload payload) async {
    final message = payload.toSmsMessage();
    try {
      if (onSendSms != null) {
        final ok = await onSendSms!(gatewayPhone, message);
        if (!ok) return SyncResult.fail(SyncChannel.sms, 'Native SMS send failed');
        return const SyncResult(success: true, channel: SyncChannel.sms);
      }

      // Dev/prototype path: post directly to inbound parser
      final res = await _dio.post('/api/v1/sync/sms-inbound', data: {
        'raw_message': message,
        'secret': smsInboundSecret,
      });
      final data = res.data as Map<String, dynamic>;
      return SyncResult(
        success: true,
        channel: SyncChannel.sms,
        serverId: data['id'] as String?,
      );
    } catch (e) {
      return SyncResult.fail(SyncChannel.sms, e.toString());
    }
  }

  @override
  Future<SyncResult> sendFullPayload(FullPayload payload) async {
    // SMS cannot carry full media — degrade to critical
    return sendCriticalPayload(CriticalPayload.fromReport(payload.report));
  }
}
