# 🌐 P2P Mesh Protocol & Packet Specification
## Raksha: Offline Peer-to-Peer Emergency Mesh Network & IoT Safety System

---

## 1. Network Topology: Ad-Hoc Dynamic Cluster
Raksha operates on an infrastructure-less **P2P Cluster** topology. Unlike strict client-server or tree models:
- Every smartphone acts simultaneously as an **Access Point (Advertiser)** and a **Station (Browser)**.
- Nodes form overlapping clusters where an intermediary node bridging two isolated clusters serves as a **Relay Gateway**.

```
Cluster Alpha                      Cluster Beta
 [ Node 1 ] ──┐                  ┌── [ Node 4 ]
              ▼                  ▼
          [ Node 2 ] <========> [ Node 3 ]  (Bridge Link)
              ▲                  ▲
 [ Node 5 ] ──┘                  └── [ Node 6 ]
```

---

## 2. Wire Protocol & Packet Schemas

### 2.1 Emergency Alert Packet (SOS Broadcast)
```json
{
  "alert_id": "ALERT_C912D450",
  "sender_id": "Android_Victim_A",
  "alert_type": "ACCIDENT_MEDICAL",
  "severity": "RED_CRITICAL",
  "location": {
    "lat": 28.758521,
    "lng": 77.109314
  },
  "description": "🚨 Physical Wearable SOS Button Pressed",
  "timestamp": "2026-09-24 14:30:15",
  "ttl_hops": 5
}
```

#### Field Specifications:
- `alert_id` (*String*): Globally unique incident identifier prefixed with `ALERT_` followed by an 8-character uppercase hex token.
- `sender_id` (*String*): Device hardware or assigned node pseudonym.
- `alert_type` (*Enum*):
  - `ACCIDENT_MEDICAL`: Medical trauma, vehicular accident, cardiac incident.
  - `SECURITY_THREAT`: Active physical assault, robbery, threat in transit.
  - `FIRE_HAZARD`: Structural or chemical fire, smoke entrapment.
- `severity` (*Enum*):
  - `RED_CRITICAL`: Immediate threat to life ($TTL=5$, highest audible alarm).
  - `YELLOW_HIGH`: Urgent assistance requested ($TTL=3$, high alert).
  - `GREEN_MODERATE`: Informational advisory or responder dispatch ($TTL=2$).
- `location` (*Object*): WGS84 coordinates with 6 decimal places ($~0.11\text{ m}$ ground accuracy).
- `ttl_hops` (*Integer*): Maximum number of remaining relay hops.

### 2.2 Offline Mesh Text Message Packet
```json
{
  "sender_name": "Rescuer Node 2",
  "chat_text": "Medical supplies available at Gate 4 assembly point"
}
```

---

## 3. Hop Math & Flood Storm Mitigation

### 3.1 Time-To-Live (TTL) Decay
To prevent infinite routing loops in cyclic graphs:
$$TTL_{t+1} = \max(0, TTL_t - 1)$$
When $TTL = 0$, the node processes the packet locally for its user and IoT hardware, but **refuses to forward** the packet further.

### 3.2 Cryptographic Digest Loop Prevention
Every receiving node performs atomic lookup against its local `relay_log` Hive box:
$$\text{Filter}(P) = \begin{cases} \text{DROP}, & \text{if } P.alert\_id \in \text{Box}(\text{"relay\_log"}) \\ \text{PROCESS \& LOG}, & \text{otherwise} \end{cases}$$
Because writes to `relay_log` are instantaneous synchronous key insertions, even simultaneous reception from multiple neighbors guarantees that only the earliest arrival is propagated.
