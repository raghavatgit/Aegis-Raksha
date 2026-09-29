class MeshPacket {
  final int senderId;
  final int destId;
  final List<int> payload;

  const MeshPacket({required this.senderId, required this.destId, required this.payload});
}
