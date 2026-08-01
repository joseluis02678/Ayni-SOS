import 'package:mesh_transport/src/mesh_message.dart';

/// Abstract mesh network — swap BLE/Wi-Fi Direct impl without touching domain.
abstract class MeshNetworkService {
  Future<void> start({required String nodeId});

  Future<void> stop();

  Future<List<MeshPeer>> discoverPeers();

  /// Store-and-forward relay with TTL and loop prevention.
  Future<void> relayMessage(MeshMessage message);

  /// Messages waiting to be delivered when a bridge node appears.
  Future<List<MeshMessage>> pendingMessages();

  Stream<MeshMessage> get incoming;
}
