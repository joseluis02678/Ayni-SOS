import 'package:core/core.dart';
import 'package:sync_engine/src/payloads.dart';
import 'package:sync_engine/src/sync_transport.dart';

/// Selects the best available transport: HTTP > SMS > Mesh.
class TransportRouter {
  TransportRouter(this._transports);

  final List<SyncTransport> _transports;

  Future<TransportCapability> probeBest() async {
    TransportCapability? bestCritical;
    for (final t in _transports) {
      final cap = await t.probe();
      if (cap.canSendFull) return cap;
      if (cap.canSendCritical && bestCritical == null) bestCritical = cap;
    }
    return bestCritical ?? TransportCapability.none;
  }

  Future<SyncResult> sendCritical(CriticalPayload payload) async {
    for (final t in _transports) {
      final cap = await t.probe();
      if (!cap.canSendCritical) continue;
      final result = await t.sendCriticalPayload(payload);
      if (result.success) return result;
    }
    return SyncResult.fail(SyncChannel.mesh, 'All critical transports failed');
  }

  Future<SyncResult> sendFull(FullPayload payload) async {
    for (final t in _transports) {
      final cap = await t.probe();
      if (!cap.canSendFull) continue;
      final result = await t.sendFullPayload(payload);
      if (result.success) return result;
    }
    // Fallback to critical
    return sendCritical(CriticalPayload.fromReport(payload.report));
  }
}
