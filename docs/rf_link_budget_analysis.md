# RF Link Budget and Propagation Analysis

## Link Budget Formula
Prx (dBm) = Ptx (dBm) + Gtx (dBi) - FSL (dB) - Lmisc (dB) + Grx (dBi)

Where:
- Free Space Path Loss (FSL): 20 log10(d) + 20 log10(f) + 32.44
- Frequency: 868.0 MHz (LoRa Band)
- Transmit Power: +14 dBm (25 mW)
- Receiver Sensitivity: -137 dBm (SF12, 125 kHz BW)
- Available Link Margin at 5 km: +18.4 dB
