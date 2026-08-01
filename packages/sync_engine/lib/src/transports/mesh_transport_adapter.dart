import 'package:core/core.dart';
import 'package:mesh_transport/mesh_transport.dart';
import 'package:sync_engine/src/payloads.dart';
import 'package:sync_engine/src/sync_transport.dart';

/// Scenario 3: opportunistic BLE / Wi-Fi Direct mesh relay.
class MeshTransportAdapter implements SyncTransport {
  MeshTransportAdapter(this._mesh);

  final MeshNetworkService _mesh;

  @override
  SyncChannel get channel => SyncChannel.mesh;

  @override
  Future<TransportCapability> probe() async {
    final peers = await _mesh.discoverPeers();
    if (peers.isEmpty) {
      return const TransportCapability(
        canSendCritical: true, // store locally for later relay
        canSendFull: false,
        channel: SyncChannel.mesh,
        description: 'Mesh — store-and-forward (no peers yet)',
      );
    }
    return TransportCapability(
      canSendCritical: true,
      canSendFull: false,
      channel: SyncChannel.mesh,
      description: 'Mesh — ${peers.length} peer(s)',
    );
  }

  @override
  Future<SyncResult> sendCriticalPayload(CriticalPayload payload) async {
    try {
      await _mesh.relayMessage(
        MeshMessage(
          id: payload.clientReportId,
          payload: payload.toMeshJson(),
          ttl: 8,
          hopCount: 0,
        ),
      );
      return const SyncResult(success: true, channel: SyncChannel.mesh);
    } catch (e) {
      return SyncResult.fail(SyncChannel.mesh, e.toString());
    }
  }

  @override
  Future<SyncResult> sendFullPayload(FullPayload payload) {
    return sendCriticalPayload(CriticalPayload.fromReport(payload.report));
  }
}
