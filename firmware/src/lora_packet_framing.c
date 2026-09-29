#include "lora_packet_framing.h"
#include <string.h>

bool lora_pack_frame(LoRaPacket* packet, uint8_t sender, uint8_t dest, uint16_t seq, const uint8_t* payload, uint8_t len) {
    if (len > LORA_MAX_PAYLOAD || !packet) return false;
    packet->magic = LORA_MAGIC_BYTE;
    packet->sequence_id = seq;
    packet->sender_node_id = sender;
    packet->dest_node_id = dest;
    packet->payload_length = len;
    memcpy(packet->payload, payload, len);
    packet->crc16 = compute_crc16((const uint8_t*)packet, sizeof(LoRaPacket) - sizeof(uint16_t));
    return true;
}

bool lora_unpack_frame(const uint8_t* raw_buffer, size_t buffer_len, LoRaPacket* out_packet) {
    if (buffer_len < sizeof(LoRaPacket) || !out_packet) return false;
    memcpy(out_packet, raw_buffer, sizeof(LoRaPacket));
    if (out_packet->magic != LORA_MAGIC_BYTE) return false;
    uint16_t expected_crc = compute_crc16(raw_buffer, sizeof(LoRaPacket) - sizeof(uint16_t));
    return out_packet->crc16 == expected_crc;
}
