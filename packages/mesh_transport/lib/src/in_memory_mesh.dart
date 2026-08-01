import 'dart:async';

import 'package:mesh_transport/src/mesh_message.dart';
import 'package:mesh_transport/src/mesh_network_service.dart';

/// In-memory / simulated mesh for research prototype and unit tests.
///
/// Production: replace with flutter_mesh_network / Nearby Connections adapter
/// that implements [MeshNetworkService] without changing sync_engine.
class InMemoryMeshNetwork implements MeshNetworkService {
  String? _nodeId;
  final List<MeshMessage> _store = [];
  final List<MeshPeer> _peers = [];
  final _controller = StreamController<MeshMessage>.broadcast();
  final Set<String> _seen = {};

  void seedPeer(MeshPeer peer) => _peers.add(peer);

  @override
  Future<void> start({required String nodeId}) async {
    _nodeId = nodeId;
  }

  @override
  Future<void> stop() async {
    await _controller.close();
  }

  @override
  Future<List<MeshPeer>> discoverPeers() async => List.unmodifiable(_peers);

  @override
  Future<void> relayMessage(MeshMessage message) async {
    if (message.expired) return;
    if (_seen.contains(message.id)) return;
    _seen.add(message.id);

    final nodeId = _nodeId ?? 'unknown';
    if (message.visited.contains(nodeId)) return;

    final hopped = message.hop(nodeId);
    _store.add(hopped);
    _controller.add(hopped);

    // Simulate flood to peers (in real impl: BLE GATT / Wi-Fi Direct)
    for (final _ in _peers) {
      // Peers would receive via radio — here we just keep in store.
    }
  }

  @override
  Future<List<MeshMessage>> pendingMessages() async => List.unmodifiable(_store);

  @override
  Stream<MeshMessage> get incoming => _controller.stream;

  /// Bridge node with connectivity calls this to flush to HTTP.
  Future<List<MeshMessage>> flushForBridge() async {
    final copy = List<MeshMessage>.from(_store);
    _store.clear();
    return copy;
  }
}
