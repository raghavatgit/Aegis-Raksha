import asyncio
import struct

class SerialLoRaBridge:
    def __init__(self, port: str = "/dev/ttyUSB0", baudrate: int = 115200):
        self.port = port
        self.baudrate = baudrate
        self.running = False

    async def start_bridge(self):
        self.running = True
        while self.running:
            await asyncio.sleep(0.1)

    def decode_raw_packet(self, data: bytes) -> dict:
        if len(data) < 7:
            return {}
        magic, seq, src, dst, length = struct.unpack("<BHBBB", data[:6])
        if magic != 0xA5:
            return {}
        return {"seq": seq, "src": src, "dst": dst, "payload": data[6:6+length]}
