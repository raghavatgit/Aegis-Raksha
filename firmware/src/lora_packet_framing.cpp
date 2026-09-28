#include <stdint.h>
#include <stddef.h>
#include <string.h>

#define PACKET_MAGIC 0xAE61
#define MAX_PAYLOAD_SIZE 220

struct __attribute__((packed)) MeshHeader {
    uint16_t magic;
    uint32_t sender_id;
    uint32_t recipient_id;
    uint16_t sequence_num;
    uint8_t hop_count;
    uint8_t payload_len;
    uint16_t crc16;
};

uint16_t compute_crc16(const uint8_t *data, size_t len) {
    uint16_t crc = 0xFFFF;
    while (len--) {
        crc ^= *data++;
        for (int i = 0; i < 8; i++) {
            if (crc & 1) crc = (crc >> 1) ^ 0xA001;
            else crc = crc >> 1;
        }
    }
    return crc;
}
