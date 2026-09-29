#ifndef TELEMETRY_RING_BUFFER_H
#define TELEMETRY_RING_BUFFER_H

#include <stdint.h>
#include <stdbool.h>

#define BUFFER_CAPACITY 64

typedef struct {
    float ax, ay, az;
    float gx, gy, gz;
    uint32_t timestamp_ms;
} ImuSample;

typedef struct {
    ImuSample buffer[BUFFER_CAPACITY];
    volatile uint8_t head;
    volatile uint8_t tail;
} TelemetryRingBuffer;

static inline void ring_buffer_init(TelemetryRingBuffer* rb) {
    rb->head = 0;
    rb->tail = 0;
}

static inline bool ring_buffer_push(TelemetryRingBuffer* rb, ImuSample sample) {
    uint8_t next_head = (rb->head + 1) % BUFFER_CAPACITY;
    if (next_head == rb->tail) return false;
    rb->buffer[rb->head] = sample;
    rb->head = next_head;
    return true;
}

static inline bool ring_buffer_pop(TelemetryRingBuffer* rb, ImuSample* out) {
    if (rb->head == rb->tail) return false;
    *out = rb->buffer[rb->tail];
    rb->tail = (rb->tail + 1) % BUFFER_CAPACITY;
    return true;
}

#endif
