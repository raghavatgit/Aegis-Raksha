#ifndef MESH_PROTOCOL_DEFS_H
#define MESH_PROTOCOL_DEFS_H

typedef enum {
    MSG_TYPE_HEARTBEAT    = 0x01,
    MSG_TYPE_DISTRESS     = 0x02,
    MSG_TYPE_ACK          = 0x03,
    MSG_TYPE_ROUTE_REQ    = 0x04,
    MSG_TYPE_ROUTE_REPLY  = 0x05,
    MSG_TYPE_TELEMETRY    = 0x06
} MeshMessageType;

typedef enum {
    PRIORITY_CRITICAL = 0x00,
    PRIORITY_HIGH     = 0x01,
    PRIORITY_NORMAL   = 0x02,
    PRIORITY_BULK     = 0x03
} MessagePriority;

#define DEFAULT_MESH_TTL 7
#define MAX_RETRY_COUNT  3

#endif
