#ifndef FIRMWARE_INCLUDE_AEGIS_CONFIG_H
#define FIRMWARE_INCLUDE_AEGIS_CONFIG_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint32_t header_flags;
    uint32_t payload_len;
    uint64_t timestamp_us;
} AegisRaksha_packet_t;

bool AegisRaksha_initialize_subsystem(void);
bool AegisRaksha_dispatch_packet(const AegisRaksha_packet_t* packet);

#ifdef __cplusplus
}
#endif

#endif // FIRMWARE_INCLUDE_AEGIS_CONFIG_H
