import 'package:flutter_test/flutter_test.dart';
import 'package:mesh_transport/mesh_transport.dart';

void main() {
  test('store-and-forward deduplicates by message id', () async {
    final mesh = InMemoryMeshNetwork();
    await mesh.start(nodeId: 'node-a');
    mesh.seedPeer(const MeshPeer(id: 'node-b', name: 'Peer B'));

    final msg = MeshMessage(
      id: 'msg-1',
      payload: {'client_report_id': 'r1', 'priority': 1},
      ttl: 5,
    );

    await mesh.relayMessage(msg);
    await mesh.relayMessage(msg); // duplicate
    final pending = await mesh.pendingMessages();
    expect(pending.length, 1);
    expect(pending.first.hopCount, 1);
  });

  test('expired messages are dropped', () async {
    final mesh = InMemoryMeshNetwork();
    await mesh.start(nodeId: 'node-a');
    final msg = MeshMessage(id: 'old', payload: {}, ttl: 0);
    await mesh.relayMessage(msg);
    expect(await mesh.pendingMessages(), isEmpty);
  });
}
