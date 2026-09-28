#ifndef PACKET_PROTOCOL_SPEC_H
#define PACKET_PROTOCOL_SPEC_H

#include <stdint.h>

enum PacketType {
    MSG_TYPE_BROADCAST = 0x01,
    MSG_TYPE_DIRECT = 0x02,
    MSG_TYPE_ACK = 0x03,
    MSG_TYPE_BEACON = 0x04,
    MSG_TYPE_SOS = 0xFF
};

#endif
