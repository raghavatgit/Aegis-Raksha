# Controlled Flooding and TTL Damping in LoRa Meshes

## Prevention Invariants
1. Sequence Cache: Nodes cache `(sender_id, sequence_id)` for 300 seconds.
2. Hop Penalty: Every relay decrements TTL by 1. Packets with TTL=0 are dropped immediately.
3. Jitter Delay: Nodes apply random backoff `(0 - 50ms)` before relaying to avoid packet collisions.
