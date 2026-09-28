#include <stdint.h>
#include <stdbool.h>

#define ROUTE_CACHE_SIZE 64

struct RouteEntry {
    uint32_t dest_id;
    uint32_t next_hop;
    uint8_t metric;
    uint32_t last_seen_ms;
};

static struct RouteEntry routing_table[ROUTE_CACHE_SIZE];

bool route_packet(uint32_t dest_id, uint32_t *next_hop_out) {
    for (int i = 0; i < ROUTE_CACHE_SIZE; i++) {
        if (routing_table[i].dest_id == dest_id) {
            *next_hop_out = routing_table[i].next_hop;
            return true;
        }
    }
    return false; // Flood packet as fallback
}
