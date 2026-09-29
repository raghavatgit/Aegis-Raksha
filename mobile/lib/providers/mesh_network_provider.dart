class MeshNode {
  final int id;
  final int hops;
  final double rssi;
  final DateTime lastSeen;

  MeshNode({required this.id, required this.hops, required this.rssi, required this.lastSeen});
}

class MeshNetworkState {
  final Map<int, MeshNode> nodes;
  MeshNetworkState({this.nodes = const {}});

  MeshNetworkState copyWithUpdatedNode(MeshNode node) {
    final updated = Map<int, MeshNode>.from(nodes);
    updated[node.id] = node;
    return MeshNetworkState(nodes: updated);
  }
}
