# RF Mesh Packet Propagation Analysis

## Link Budget Formula
$$P_{rx} = P_{tx} + G_{tx} + G_{rx} - L_{fs} - L_{misc}$$
Where:
- $P_{tx}$: Transmitter output power (+22 dBm for SX1262)
- $G_{tx}, G_{rx}$: Antenna gain (+2.5 dBi omnidirectional)
- $L_{fs}$: Free space path loss: $20 \log_{10}(d) + 20 \log_{10}(f) - 147.55$
- Receiver Sensitivity: -137 dBm at SF12 / 125 kHz BW
