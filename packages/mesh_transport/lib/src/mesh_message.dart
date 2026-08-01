class MeshPeer {
  const MeshPeer({required this.id, required this.name, this.rssi});

  final String id;
  final String name;
  final int? rssi;
}

class MeshMessage {
  MeshMessage({
    required this.id,
    required this.payload,
    this.ttl = 8,
    this.hopCount = 0,
    Set<String>? visited,
  }) : visited = visited ?? {};

  final String id;
  final Map<String, dynamic> payload;
  final int ttl;
  final int hopCount;
  final Set<String> visited;

  bool get expired => hopCount >= ttl || ttl <= 0;

  MeshMessage hop(String nodeId) {
    return MeshMessage(
      id: id,
      payload: payload,
      ttl: ttl - 1,
      hopCount: hopCount + 1,
      visited: {...visited, nodeId},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payload': payload,
        'ttl': ttl,
        'hop_count': hopCount,
        'visited': visited.toList(),
      };

  factory MeshMessage.fromJson(Map<String, dynamic> json) => MeshMessage(
        id: json['id'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        ttl: json['ttl'] as int? ?? 8,
        hopCount: json['hop_count'] as int? ?? 0,
        visited: (json['visited'] as List?)?.cast<String>().toSet() ?? {},
      );
}
