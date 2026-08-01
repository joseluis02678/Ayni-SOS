import 'package:core/core.dart';
import 'package:sync_engine/src/payloads.dart';

class TransportCapability {
  const TransportCapability({
    required this.canSendCritical,
    required this.canSendFull,
    required this.channel,
    this.description = '',
  });

  final bool canSendCritical;
  final bool canSendFull;
  final SyncChannel channel;
  final String description;

  static const none = TransportCapability(
    canSendCritical: false,
    canSendFull: false,
    channel: SyncChannel.mesh,
    description: 'No transport available',
  );
}

class SyncResult {
  const SyncResult({
    required this.success,
    required this.channel,
    this.serverId,
    this.message,
  });

  final bool success;
  final SyncChannel channel;
  final String? serverId;
  final String? message;

  factory SyncResult.fail(SyncChannel channel, String message) =>
      SyncResult(success: false, channel: channel, message: message);
}

/// Strategy interface — implementations are interchangeable (ADR-005).
abstract class SyncTransport {
  SyncChannel get channel;

  Future<TransportCapability> probe();

  Future<SyncResult> sendCriticalPayload(CriticalPayload payload);

  Future<SyncResult> sendFullPayload(FullPayload payload);
}
