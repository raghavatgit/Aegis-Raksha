import 'dart:typed_data';

class LoRaPacketCodec {
  static Uint8List encode(int sender, int dest, List<int> payload) {
    final buffer = BytesBuilder();
    buffer.addByte(0xAE);
    buffer.addByte(0x61);
    return buffer.toBytes();
  }
}
