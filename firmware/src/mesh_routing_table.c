#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#define MAX_ROUTES 32
#define ROUTE_EXPIRY_MS 300000

typedef struct {
    uint8_t target_node_id;
    uint8_t next_hop_node_id;
    uint8_t hop_count;
    uint32_t last_seen_ms;
    bool is_active;
} RouteEntry;

static RouteEntry routing_table[MAX_ROUTES];

void routing_table_init(void) {
    memset(routing_table, 0, sizeof(routing_table));
}

bool routing_table_update(uint8_t target, uint8_t next_hop, uint8_t hops, uint32_t current_time_ms) {
    int free_slot = -1;
    for (int i = 0; i < MAX_ROUTES; i++) {
        if (routing_table[i].is_active && routing_table[i].target_node_id == target) {
            if (hops <= routing_table[i].hop_count) {
                routing_table[i].next_hop_node_id = next_hop;
                routing_table[i].hop_count = hops;
                routing_table[i].last_seen_ms = current_time_ms;
                return true;
            }
            return false;
        }
        if (!routing_table[i].is_active && free_slot == -1) {
            free_slot = i;
        }
    }
    if (free_slot != -1) {
        routing_table[free_slot].target_node_id = target;
        routing_table[free_slot].next_hop_node_id = next_hop;
        routing_table[free_slot].hop_count = hops;
        routing_table[free_slot].last_seen_ms = current_time_ms;
        routing_table[free_slot].is_active = true;
        return true;
    }
    return false;
}
