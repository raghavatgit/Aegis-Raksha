#!/usr/bin/env python3
"""
Raksha Emergency Mesh - IoT Hardware to Phone USB Cable Bridge (Python)
Bridges ESP32 (USB Serial) <-> Phone App (USB ADB)
"""

import sys
import time
import socket
import subprocess
import glob

def find_adb():
    candidates = [
        "adb",
        r"C:\Users\Harshit\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        r"C:\Users\Harshit\AppData\Local\Android\sdk\platform-tools\adb.exe",
    ]
    for c in candidates:
        try:
            res = subprocess.run([c, "version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if res.returncode == 0:
                return c
        except Exception:
            continue
    return "adb"

def setup_adb_ports(adb_bin, port=8888):
    print(f"[*] Setting up ADB USB Cable Tunnel on port {port}...")
    try:
        subprocess.run([adb_bin, "forward", f"tcp:{port}", f"tcp:{port}"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        subprocess.run([adb_bin, "reverse", f"tcp:{port}", f"tcp:{port}"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"[+] ADB Port forwarding active (forward & reverse on tcp:{port})")
    except Exception as e:
        print(f"[!] Warning running ADB: {e}")

def get_serial_ports():
    try:
        import serial.tools.list_ports
        return list(serial.tools.list_ports.comports())
    except ImportError:
        print("[!] pyserial not found. Install it with: pip install pyserial")
        sys.exit(1)

def main():
    print("=" * 60)
    print("   🛡️ RAKSHA EMERGENCY MESH - IoT USB TO PHONE BRIDGE")
    print("   ESP32 (USB Cable) <--> Laptop <--> Phone (USB ADB Cable)")
    print("=" * 60)

    adb_bin = find_adb()
    setup_adb_ports(adb_bin, 8888)

    ports = get_serial_ports()
    if not ports:
        print("[-] No Serial COM ports found! Plug in your ESP32 via USB.")
        sys.exit(1)

    print("\nDetected COM Ports:")
    esp_idx = 0
    for idx, p in enumerate(ports):
        desc = f"{p.device}: {p.description}"
        is_esp = any(k in desc.lower() for k in ["cp210", "ch340", "uart", "silicon", "usb serial"])
        if is_esp:
            esp_idx = idx
            desc += " ⭐ [RECOMMENDED ESP32]"
        print(f"  [{idx}] {desc}")

    if len(ports) == 1:
        chosen_port = ports[0].device
        print(f"[+] Auto-selected only COM port: {chosen_port}")
    else:
        choice = input(f"Select port index (default {esp_idx}: {ports[esp_idx].device}): ").strip()
        if choice.isdigit() and int(choice) < len(ports):
            chosen_port = ports[int(choice)].device
        else:
            chosen_port = ports[esp_idx].device

    import serial
    print(f"\n[*] Opening {chosen_port} at 115200 baud...")
    try:
        ser = serial.Serial(chosen_port, 115200, timeout=0.1)
        print(f"[+] Serial port {chosen_port} OPEN.")
    except Exception as e:
        print(f"[-] Error opening {chosen_port}: {e}")
        print("    (If Arduino Serial Monitor is open, please close it first!)")
        sys.exit(1)

    print("\n[*] Connecting to Raksha Mobile App on Phone (127.0.0.1:8888)...")
    sock = None
    for attempt in range(1, 7):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(1.0)
            s.connect(("127.0.0.1", 8888))
            sock = s
            print("[+] Connected to Raksha Mobile App over USB cable!")
            break
        except Exception:
            print(f"    Waiting for Phone App (attempt {attempt}/6)...")
            time.sleep(2)

    print("\n" + "=" * 60)
    print("  🚀 BRIDGE IS LIVE! DATA FLOWING BETWEEN ESP32 & PHONE APP")
    print("=" * 60)
    print("  🔘 Press ESP32 Button (GPIO 4)")
    print("  🎙️ Clap / Scream near Mic (GPIO 18)")
    print("  📱 Tap Red SOS in Mobile App")
    print("=" * 60 + "\n")

    try:
        while True:
            # 1. Read from ESP32 Serial
            if ser.in_waiting > 0:
                line = ser.readline().decode("utf-8", errors="ignore").strip()
                if line:
                    t = time.strftime("%H:%M:%S")
                    if "SOS_TRIGGERED" in line:
                        print(f"[{t}] 🚨 ESP32 ALERT TRIGGERED -> App: {line}")
                    elif "ALERT_RESET" in line:
                        print(f"[{t}] 🛡️ ESP32 ALERT RESET -> App: {line}")
                    elif "HEARTBEAT" in line:
                        print(f"[{t}] 💓 ESP32 Telemetry: {line}")
                    else:
                        print(f"[{t}] 📡 ESP32: {line}")

                    if sock:
                        try:
                            sock.sendall((line + "\n").encode("utf-8"))
                        except Exception as e:
                            print(f"[{t}] Warning sending to phone: {e}")

            # 2. Read from Phone App Socket
            if sock:
                try:
                    sock.settimeout(0.01)
                    data = sock.recv(1024)
                    if data:
                        cmd = data.decode("utf-8", errors="ignore").strip()
                        t = time.strftime("%H:%M:%S")
                        print(f"[{t}] 📱 Phone App Command: '{cmd}' -> ESP32")
                        ser.write((cmd + "\n").encode("utf-8"))
                except socket.timeout:
                    pass
                except Exception:
                    pass

            time.sleep(0.01)
    except KeyboardInterrupt:
        print("\nStopping bridge...")
    finally:
        ser.close()
        if sock:
            sock.close()
        print("Done.")

if __name__ == "__main__":
    main()
