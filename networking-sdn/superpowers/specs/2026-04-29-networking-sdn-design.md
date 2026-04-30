---
name: Networking SDN Design
description: Complete architecture and implementation plan for three-layer networking SDN portfolio project
type: design
date: 2026-04-29
---

# Chakraview Networking-SDN: Complete Design

## Executive Summary

A three-layer portfolio project showcasing modern networking architecture: **Foundation** (high-performance packet processing via DPDK vs eBPF), **Control Plane** (SDN controller with intent-based APIs), and **Fabric Protocols** (BGP, VXLAN, EVPN). All three layers integrate into a deployable Docker Compose lab where a network fabric can be spun up, configured, and tested end-to-end.

**Key Characteristics:**
- Equal depth across all three layers (one-third complexity each)
- Monorepo with clear subsystem boundaries
- Runnable, not just documentation—everything deployable and testable
- Production-inspired architecture with extension points marked for future development

---

## Part 1: Repository Structure & Organization

```
chakraview-networking-sdn/
├── foundation/
│   ├── dpdk/                 # C — user-space packet processing
│   │   ├── src/
│   │   │   ├── main.c        # DPDK app entry point
│   │   │   ├── forwarding.c  # L2/L3 forwarding logic
│   │   │   ├── vxlan.c       # VXLAN encapsulation/decapsulation
│   │   │   └── filter.c      # Packet filtering
│   │   ├── Makefile
│   │   └── README.md
│   │
│   ├── ebpf/                 # Rust + libbpf — kernel-resident packet processing
│   │   ├── src/
│   │   │   ├── main.rs       # eBPF program loader
│   │   │   ├── xdp.rs        # XDP hook programs
│   │   │   ├── tc.rs         # TC hook programs
│   │   │   └── common.rs     # Shared logic
│   │   ├── Cargo.toml
│   │   └── README.md
│   │
│   ├── benchmarks/
│   │   ├── compare.py        # Throughput/latency/CPU comparison
│   │   └── results/          # Benchmark outputs
│   │
│   └── docs/
│       ├── dpdk-guide.md     # DPDK implementation details
│       ├── ebpf-guide.md     # eBPF implementation details
│       └── tradeoffs.md      # Detailed trade-off analysis
│
├── controller/               # Go — SDN control plane
│   ├── cmd/
│   │   ├── sdn-controller/
│   │   │   └── main.go       # HTTP/gRPC server entrypoint
│   │   └── cli/              # CLI tool for testing
│   │
│   ├── pkg/
│   │   ├── northbound/
│   │   │   ├── http.go       # REST API handlers
│   │   │   ├── grpc.go       # gRPC service definitions
│   │   │   └── models.go     # Request/response types
│   │   │
│   │   ├── southbound/
│   │   │   ├── protocol.go   # Device communication protocol
│   │   │   ├── client.go     # Fabric node client
│   │   │   └── messages.go   # Protocol messages
│   │   │
│   │   ├── topology/
│   │   │   ├── discovery.go  # Device discovery
│   │   │   ├── graph.go      # Network topology graph
│   │   │   └── state.go      # Topology state management
│   │   │
│   │   ├── policy/
│   │   │   ├── engine.go     # Policy evaluation engine
│   │   │   ├── rules.go      # Policy rule definitions
│   │   │   └── compiler.go   # Intent to config compilation
│   │   │
│   │   └── store/
│   │       └── config.go     # In-memory config store (EXTEND: etcd)
│   │
│   ├── api/
│   │   ├── openapi.yaml      # OpenAPI spec for REST API
│   │   └── fabric.proto      # Protobuf definitions for gRPC
│   │
│   ├── Dockerfile
│   ├── go.mod
│   ├── go.sum
│   └── README.md
│
├── fabric/                   # Python — fabric protocols
│   ├── bgp/
│   │   ├── speaker.py        # BGP speaker implementation
│   │   ├── fsm.py            # BGP state machine
│   │   ├── messages.py       # BGP message encoding/decoding
│   │   └── routes.py         # Route advertisement, best-path
│   │
│   ├── vxlan/
│   │   ├── tunnel.py         # VXLAN tunnel management
│   │   ├── encap.py          # Packet encapsulation/decapsulation
│   │   └── learning.py       # MAC learning (simplified)
│   │
│   ├── evpn/
│   │   ├── routes.py         # EVPN route types (Type 2, Type 5, etc.)
│   │   ├── integration.py    # EVPN-BGP integration
│   │   └── services.py       # EVPN services (E-LAN, E-Line)
│   │
│   ├── device.py             # Simulated switch/router
│   ├── forwarding.py         # Forwarding table and state
│   ├── requirements.txt
│   └── README.md
│
├── lab/                      # Deployable environment
│   ├── docker-compose.yml    # Service definitions
│   ├── Dockerfile.dpdk       # DPDK handler container
│   ├── Dockerfile.ebpf       # eBPF agent container
│   ├── Dockerfile.controller # Controller container
│   ├── Dockerfile.fabric     # Fabric node container
│   ├── Dockerfile.traffic    # Traffic generator
│   │
│   ├── scripts/
│   │   ├── init.sh           # Lab initialization
│   │   ├── topology.yaml     # Network topology definition
│   │   ├── config.yaml       # Initial controller config
│   │   └── traffic.py        # Traffic generation and validation
│   │
│   └── README.md
│
├── docs/
│   ├── adrs/
│   │   ├── ADR-0001-monorepo-architecture.md
│   │   ├── ADR-0002-dpdk-vs-ebpf.md
│   │   ├── ADR-0003-go-control-plane.md
│   │   ├── ADR-0004-bgp-vxlan-evpn.md
│   │   ├── ADR-0005-simulated-fabric.md
│   │   ├── ADR-0006-northbound-apis.md
│   │   ├── ADR-0007-southbound-protocol.md
│   │   └── ADR-0008-lab-driven-development.md
│   │
│   ├── architecture.md       # System design overview
│   ├── integration.md        # Layer integration details
│   ├── foundation.md         # Foundation layer deep-dive
│   ├── controller.md         # Controller deep-dive
│   ├── fabric.md             # Fabric protocols deep-dive
│   ├── quickstart.md         # Get started guide
│   ├── extending.md          # Extension points guide
│   └── superpowers/
│       └── specs/
│           └── 2026-04-29-networking-sdn-design.md
│
├── mkdocs.yml
└── README.md
```

---

## Part 2: Foundation Layer (DPDK vs eBPF)

### Purpose
Showcase two complementary high-performance packet processing architectures with runnable implementations and direct performance comparisons.

### DPDK Component (C)

**Scope:**
- User-space packet processing library
- Direct NIC access, zero-copy ring buffers, CPU affinity
- Implements: L2/L3 forwarding, VXLAN encapsulation/decapsulation, packet filtering
- Runs as a standalone binary attached to veth interface in lab

**Key Modules:**
- `forwarding.c` — Basic L2 (MAC) and L3 (IP) forwarding logic
- `vxlan.c` — VXLAN header construction/parsing, tunnel management
- `filter.c` — Per-flow packet filtering (drop/allow rules from controller)
- Batched packet processing (16-32 packets per burst) to amortize overhead

**Performance Targets:**
- ~10M+ packets/sec (on single core)
- Sub-microsecond latency for forwarding decision
- Minimal CPU overhead per packet

**Extension Points (Marked `// TODO: EXTEND:`):**
- QoS and traffic shaping (token bucket, hierarchical schedulers)
- Load balancing algorithms (RSS, flow hashing)
- Stateful NAT, connection tracking
- Statistics collection and telemetry

### eBPF Component (Rust)

**Scope:**
- Kernel-resident packet processing via XDP and TC hooks
- Uses `libbpf-rs` for safe, ergonomic eBPF abstraction
- Implements: same forwarding/VXLAN/filtering as DPDK
- No user-space context switching, kernel integration

**Key Modules:**
- `xdp.rs` — XDP programs (early ingress path, fastest)
- `tc.rs` — TC programs (more flexible, slightly higher latency)
- `common.rs` — Shared logic (header parsing, lookups)
- Kernel maps for dynamic configuration (forwarding rules, tunnel state)

**Performance Targets:**
- ~5M+ packets/sec with XDP (kernel-resident)
- Microsecond-range latency (lower context switching)
- Smaller memory footprint than DPDK

**Extension Points (Marked `// TODO: EXTEND:`):**
- Tail calls for larger, modular programs
- Dynamic map-based configuration hot-reloading
- Connection tracking (stateful programs)

### Comparison & Benchmarks

**Head-to-Head Benchmarks:**
- Throughput (packets/sec) across packet sizes
- Latency distribution (p50, p95, p99)
- CPU utilization per throughput unit
- Memory footprint and startup time
- Development complexity (lines of code, test coverage)

**Trade-Offs Summary:**
| Aspect | DPDK | eBPF |
|--------|------|------|
| **Max throughput** | ⭐⭐⭐ Highest (userspace control) | ⭐⭐ High (kernel overhead) |
| **Latency** | ⭐⭐⭐ Lowest (dedicated cores) | ⭐⭐⭐ Very low (no syscall) |
| **Memory** | ⭐⭐ Higher (ring buffers) | ⭐⭐⭐ Lower (kernel managed) |
| **Dev complexity** | ⭐⭐ Higher (NIC drivers, memory management) | ⭐⭐⭐ Lower (kernel abstractions) |
| **Kernel integration** | ⭐⭐ Isolated (can bypass kernel features) | ⭐⭐⭐ Native (kernel visibility) |

**When to Use Each:**
- **DPDK:** Maximum performance requirement, dedicated hardware, acceptable kernel bypass
- **eBPF:** Need kernel visibility (eBPF maps, tracing), lower dev complexity, flexible deployment

**ADR-0002** documents this decision: why we implement both, trade-off rationale, production selection criteria.

### Runnable Lab Integration
- DPDK handler runs in Docker container with huge pages configured
- eBPF agent deployed as sidecar in namespace with XDP programs loaded
- Traffic generator sends same test packets through both paths
- Metrics collected side-by-side: throughput, latency, CPU, memory
- Lab script reports which one performs better for different workloads

---

## Part 3: SDN Controller Layer (Go)

### Purpose
Build the control plane intelligence that manages network intent, translates it to device configuration, and orchestrates the fabric.

### Architecture

**Northbound Plane (User-Facing APIs):**
- REST API (HTTP) for configuration and discovery
- gRPC API for real-time policy and state subscriptions
- YAML-based topology/policy declarative config
- Intent-based (user declares what they want; controller derives device config)

**Southbound Plane (Device Communication):**
- Custom gRPC protocol (simplified OpenFlow-like semantics)
- Devices register with controller on startup
- Controller sends commands: tunnel creation, route advertisement, ACL rules
- Devices report back state: tunnel status, route learned, ACL applied

**Internal Components:**

1. **Topology Service (`pkg/topology/`):**
   - Discovers connected devices (devices register via southbound API)
   - Maintains network graph (nodes = devices, edges = links)
   - Tracks device state: reachability, port status, capabilities
   - Event notifications when topology changes

2. **Policy Engine (`pkg/policy/`):**
   - Evaluates user intents against topology
   - Generates device commands from policy rules
   - Example: "enable VXLAN overlay from node-A to node-B" → derive BGP routes, create tunnels
   - Validates policies (prevent conflicting rules, check ACL sanity)

3. **Configuration Store (`pkg/store/`):**
   - In-memory persistence of network intent
   - EXTEND: Add etcd/database for HA, persistent storage
   - Change tracking for audit/rollback

4. **HTTP/gRPC Servers (`pkg/northbound/`):**
   - REST endpoints for topology queries, config apply, policy management
   - gRPC streaming for real-time updates

### Northbound API (REST)

**Key Endpoints:**

```
GET  /api/v1/topology              # List devices, links, overlay status
GET  /api/v1/topology/devices      # List registered devices
GET  /api/v1/topology/links        # List detected links
POST /api/v1/topology/devices      # Register device (usually auto)

POST /api/v1/overlays              # Create VXLAN overlay
GET  /api/v1/overlays/{id}         # Get overlay status
POST /api/v1/overlays/{id}/tunnels # Add tunnel to overlay

POST /api/v1/policies              # Apply network policy (ACL, routing intent)
GET  /api/v1/policies              # List active policies
DELETE /api/v1/policies/{id}       # Remove policy

GET  /api/v1/status                # Controller health, fabric state summary
```

**Example: Create a VXLAN Overlay**
```json
POST /api/v1/overlays
{
  "name": "overlay-prod",
  "vni": 100,
  "type": "vxlan",
  "endpoints": ["node-1", "node-2", "node-3"]
}
```

Controller derives:
- Which BGP routes to advertise (underlay reachability)
- VXLAN tunnel endpoints and VNI mappings
- Which EVPN routes to exchange (L2/L3 services)

### Southbound Protocol (gRPC)

**Service Definition:**
```protobuf
service FabricAgent {
  rpc RegisterDevice(DeviceInfo) returns (DeviceID);
  rpc GetDeviceState(DeviceID) returns (DeviceState);
  rpc CreateVxlanTunnel(TunnelConfig) returns (TunnelStatus);
  rpc AdvertiseBgpRoute(RouteAdvertisement) returns (RouteStatus);
  rpc ApplyAcl(AclRule) returns (AclStatus);
  rpc StreamDeviceEvents(DeviceID) returns (stream DeviceEvent);
}
```

Devices are gRPC clients; controller is server sending commands.

### Key Features

**Event-Driven Updates:**
- Policy change triggers southbound commands
- Device state change triggers topology update
- Cascading updates to dependent configurations

**Validation & Conflict Detection:**
- ACLs checked for contradictions before apply
- Overlay endpoints verified to exist and be reachable
- Routes checked for overlaps, priorities

**Observability Hooks:**
- All API calls logged
- Device state changes trigger events
- EXTEND: Prometheus metrics, distributed tracing

### Extension Points (Marked `// TODO: EXTEND:`)
- **BFD:** Fast failover detection (currently no failure handling)
- **NETCONF/YANG:** Richer, more standard device interaction
- **Multi-controller HA:** State sync via etcd, leader election
- **Persistent storage:** Move from in-memory to database
- **Telemetry:** Prometheus metrics, trace integration

---

## Part 4: Fabric Protocol Layer (Python Prototypes)

### Purpose
Implement the routing and overlay protocols that actually move packets through the fabric, orchestrated by the controller.

### BGP Component (`bgp/`)

**Implementation:**
- Simplified but spec-compliant BGP speaker
- Listens on TCP port `:179` for peer connections
- Implements BGP message types: OPEN, UPDATE, KEEPALIVE, NOTIFICATION
- Best-path selection: simple AS-path length + local preference
- Route advertisement and withdrawal per controller intent

**Key Classes:**
- `Speaker` — BGP process, peer management, state machine
- `FSM` — BGP Finite State Machine (Idle → Connect → Active → OpenSent → OpenConfirm → Established)
- `Messages` — Encode/decode BGP messages (OPEN, UPDATE, KEEPALIVE)
- `Routes` — Route DB, best-path computation, advertisement

**Data Structures:**
- Routing table: `{destination: next-hop, AS-path, local-pref, med}`
- Peer state: address, AS, session state, sent/received routes
- Advertisement queue: routes pending announcement

**Controller Integration:**
- Receives intent from controller: "advertise 10.0.1.0/24 from node-X"
- Fabric node's BGP speaker sends UPDATE to peers
- Peers learn routes, update their routing tables

**Example BGP UPDATE Message:**
```
UPDATE message:
  Withdrawn routes: (empty)
  Path attributes:
    ORIGIN: IGP
    AS_PATH: [AS100, AS200]
    NEXT_HOP: 192.168.1.1
    LOCAL_PREF: 100
  NLRI: 10.0.1.0/24
```

### VXLAN Component (`vxlan/`)

**Implementation:**
- VXLAN tunnel encapsulation and decapsulation
- Maps logical networks (VNIs) to physical tunnels
- Controller declares tunnel endpoints; fabric nodes set up tunnels

**Key Classes:**
- `Tunnel` — Tunnel state: source IP, destination IP, VNI, status
- `Encapsulator` — VXLAN header construction (UDP port 4789, VXLAN header)
- `LearningEngine` — Simplified MAC learning (collect source MACs, build forwarding table)
- `OverlayNetwork` — Logical network abstraction (VNI, member nodes)

**VXLAN Packet Format:**
```
[Outer Ethernet][Outer IP][UDP:4789][VXLAN Header (VNI)][Inner Ethernet][Inner IP][Payload]
```

**Controller Integration:**
- Controller command: "create VXLAN tunnel from node-A (192.168.1.1) to node-B (192.168.1.2) with VNI 100"
- Fabric nodes establish tunnel, start encapsulating traffic destined for the overlay

**Extension Points:**
- Advanced MAC learning (EVPN-based instead of flooding)
- Multicast support for broadcast/unknown-unicast
- Tunnel redundancy and load balancing

### EVPN Component (`evpn/`)

**Implementation:**
- EVPN as control plane for VXLAN overlays
- Route types: Type 2 (MAC/IP advertisement), Type 5 (IP prefix)
- Devices exchange EVPN routes via BGP (EVPN address family)
- Tunnels and forwarding rules derived from EVPN routes

**Key Classes:**
- `EvpnRoute` — Route types, encoding/decoding
- `EvpnIntegration` — Tie EVPN routes to VXLAN tunnels and BGP
- `Services` — EVPN services (E-LAN for L2, E-Line for L2-VPN, IP-VPN for L3)

**Example EVPN Route Exchange:**
```
Node-A advertises Type 2 route:
  RD: 100:1 (Route Distinguisher)
  RT: 100:100 (Route Target for import/export)
  MAC: 00:11:22:33:44:55
  IP: 10.0.1.10 (optional, MAC/IP pair)
  VXLAN_ID: 100
  Originating_Node: Node-A

Node-B receives, learns:
  Traffic to MAC 00:11:22:33:44:55 → tunnel to Node-A, VNI 100
  Traffic to 10.0.1.10 → tunnel to Node-A, VNI 100
```

**Evolution Over BGP + VXLAN:**
- Pure VXLAN: static tunnel configuration, manual MAC learning → flooding
- BGP + VXLAN: dynamic routes, but MAC learning still needed
- EVPN: unified control plane, MAC and IP learning, multi-service support

**ADR-0004** documents why we show all three: each layer builds on the previous, showing architectural evolution.

### Simulated Device Model (`device.py`)

**Class: `NetworkDevice`**
- Abstraction of a switch/router that participates in fabric
- Maintains: routing table, forwarding rules, tunnel state, BGP session state
- Can be a "core" device (full control plane) or "leaf" device (simplified state)

**Key Methods:**
- `configure_tunnel()` — Set up VXLAN tunnel (controller command)
- `advertise_route()` — Start advertising a route via BGP (controller command)
- `forward_packet()` — Simplified forwarding (state-only, no actual packet bytes in simulation)
- `handle_bgp_message()` — Process incoming BGP UPDATE, learn routes
- `get_state()` — Report current routing table, tunnel list, etc. (for controller queries)

**Simulation Model:**
- Devices communicate via TCP sockets (simulated links)
- Packet forwarding is state-driven (we track which routes are known, which tunnels exist)
- For real packet validation, we track encapsulation rules without moving actual bytes

### Lab Integration

**Docker Compose Services:**
- `fabric-node-1`, `fabric-node-2`, `fabric-node-3` — Python device instances
- Each runs `device.py` with a unique node ID, listens on southbound port (gRPC)
- Devices register with controller on startup
- Controller sends topology intent → devices execute BGP, VXLAN, EVPN state changes

**Traffic Validation:**
- Traffic generator sends packets to overlay network
- We verify encapsulation (packets are wrapped in VXLAN headers)
- We verify routing (packets follow the path computed by BGP + EVPN)
- Output: delivery success rate, end-to-end latency, protocol state consistency

### Extension Points (Marked `# TODO: EXTEND:`)
- Segment Routing (SR-MPLS) for traffic engineering
- Path computation element (PCE) for optimal tunnel placement
- EVPN redundancy modes (all-active, single-active per MAC)
- Multicast tree distribution
- Scale testing framework (100s of devices, 1000s of routes)

---

## Part 5: Integration & Lab Setup

### How Layers Connect

```
┌─────────────────────────────────────────────────────────────────┐
│ NORTHBOUND: User Intent (REST API)                              │
│ "Create overlay X with endpoints A, B, C"                       │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ CONTROLLER: Policy Engine (Go)                                  │
│ Derives: BGP routes, tunnel endpoints, EVPN routes              │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ SOUTHBOUND: Device Commands (gRPC)                              │
│ "Advertise 10.0.1.0/24 from node-A"                             │
│ "Create tunnel A→B with VNI 100"                                │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ FABRIC: Protocol Execution (Python)                             │
│ BGP speaker exchanges routes, VXLAN tunnels created, EVPN       │
│ routes distributed, forwarding rules installed                  │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ FOUNDATION: Packet Processing (DPDK or eBPF)                    │
│ Incoming packets encapsulated in VXLAN, forwarded via tunnels   │
│ based on fabric protocol state                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Critical Insight:**
- Foundation layer shows *how* packets move (performance, mechanisms)
- Upper layers show *where* packets go (routing decisions, tunnel creation)
- Integration shows the full picture: intelligent routing + efficient forwarding

### Docker Compose Lab

**File: `lab/docker-compose.yml`**

```yaml
version: '3.8'
services:
  
  # DPDK packet handler
  dpdk-handler:
    build:
      context: .
      dockerfile: Dockerfile.dpdk
    privileged: true
    volumes:
      - /dev/hugepages:/dev/hugepages
      - /sys:/sys
    networks:
      - fabric
    environment:
      - DPDK_PORT=veth0  # Attached to veth
  
  # eBPF agent (alternative to DPDK)
  ebpf-agent:
    build:
      context: .
      dockerfile: Dockerfile.ebpf
    privileged: true
    networks:
      - fabric
    environment:
      - eBPF_INTERFACE=eth0
  
  # SDN Controller
  sdn-controller:
    build:
      context: controller
      dockerfile: Dockerfile.controller
    ports:
      - "8080:8080"  # REST API
      - "9090:9090"  # gRPC
    networks:
      - fabric
    depends_on:
      - fabric-node-1
      - fabric-node-2
      - fabric-node-3
    environment:
      - CONTROLLER_ADDR=0.0.0.0:9090
  
  # Fabric nodes (BGP + VXLAN + EVPN speakers)
  fabric-node-1:
    build:
      context: .
      dockerfile: Dockerfile.fabric
    networks:
      - fabric
    environment:
      - NODE_ID=node-1
      - NODE_ADDR=10.0.0.1
      - CONTROLLER=sdn-controller:9090
  
  fabric-node-2:
    build:
      context: .
      dockerfile: Dockerfile.fabric
    networks:
      - fabric
    environment:
      - NODE_ID=node-2
      - NODE_ADDR=10.0.0.2
      - CONTROLLER=sdn-controller:9090
  
  fabric-node-3:
    build:
      context: .
      dockerfile: Dockerfile.fabric
    networks:
      - fabric
    environment:
      - NODE_ID=node-3
      - NODE_ADDR=10.0.0.3
      - CONTROLLER=sdn-controller:9090
  
  # Traffic generator & validator
  traffic-gen:
    build:
      context: .
      dockerfile: Dockerfile.traffic
    networks:
      - fabric
    depends_on:
      - sdn-controller
      - fabric-node-1
    environment:
      - CONTROLLER_URL=http://sdn-controller:8080

networks:
  fabric:
    driver: bridge
```

### Lab Initialization

**File: `lab/scripts/init.sh`**

Flow:
1. Spin up services: `docker-compose up -d`
2. Wait for controller to be ready: health check
3. Wait for fabric nodes to register: poll `/api/v1/topology/devices`
4. Load initial topology: `POST /api/v1/overlays` to create VXLAN overlay with 3 endpoints
5. Verify BGP routes are exchanged (poll fabric nodes' BGP tables)
6. Verify VXLAN tunnels are up: check tunnel status in controller
7. Run traffic test: send packets through overlay, verify encapsulation and delivery
8. Report metrics: throughput, latency, protocol state consistency

### Runnable Example: End-to-End Workflow

**1. Start the lab:**
```bash
cd lab
docker-compose up -d
./scripts/init.sh
```

**2. Query the topology:**
```bash
curl http://localhost:8080/api/v1/topology
```
Response: 3 fabric nodes, all registered and reachable

**3. Create a VXLAN overlay:**
```bash
curl -X POST http://localhost:8080/api/v1/overlays \
  -H "Content-Type: application/json" \
  -d '{
    "name": "overlay-prod",
    "vni": 100,
    "endpoints": ["node-1", "node-2", "node-3"]
  }'
```

**4. Check overlay status:**
```bash
curl http://localhost:8080/api/v1/overlays/overlay-prod
```
Response: tunnel status, EVPN routes, BGP prefix count

**5. Send traffic through the overlay:**
```bash
cd lab/scripts
python traffic.py --overlay overlay-prod --duration 10s
```
Output: packets sent, packets delivered, encapsulation verified, latency distribution

**6. Inspect fabric node state:**
```bash
docker exec fabric-node-1 python -c "
  from device import NetworkDevice
  d = NetworkDevice('node-1')
  print(d.routing_table)  # BGP-learned routes
  print(d.tunnels)       # VXLAN tunnels
  print(d.evpn_routes)   # EVPN route cache
"
```

---

## Part 6: Documentation & ADRs

### Architecture Decision Records (ADRs)

**ADR-0001: Monorepo with Three Integrated Subsystems**
- **Decision:** Single repo with three subsystems (foundation, controller, fabric), not three separate repos
- **Rationale:** Portfolio piece benefits from showing integration; separate repos fragment the story
- **Trade-off:** Build complexity vs. cohesion and demonstrating orchestration across layers

**ADR-0002: DPDK vs eBPF**
- **Decision:** Implement both with head-to-head benchmarks; neither is universally "better"
- **Rationale:** Production systems choose based on constraints; educate on trade-offs
- **Trade-off:** Implementation effort vs. depth of understanding demonstrated

**ADR-0003: Go for SDN Control Plane**
- **Decision:** Go for controller; concurrency primitives (goroutines), fast build, network libraries
- **Rationale:** Stateful systems with many concurrent device connections fit Go's strengths
- **Alternative considered:** Python (simpler) vs. Rust (safer); Go is best balance

**ADR-0004: BGP + VXLAN + EVPN Progression**
- **Decision:** Implement all three to show protocol evolution, not just final state
- **Rationale:** Understanding protocol maturity journey is deeper than final version alone
- **Trade-off:** More code vs. richer insight into design evolution

**ADR-0005: Simulated Fabric Devices**
- **Decision:** Python prototypes, not real hardware or full kernel network stack
- **Rationale:** Prototypes are runnable lab-in-a-box; real hardware is complex, harder to reason about
- **Trade-off:** Less "production real" vs. faster to build, easier to understand

**ADR-0006: Northbound REST/gRPC APIs**
- **Decision:** Intent-based APIs; user declares what, controller derives how
- **Rationale:** Scales better (less device-specific knowledge needed) than imperative command APIs
- **Alternative:** Device-centric CLI; intent-based more modern and powerful

**ADR-0007: Southbound gRPC Protocol**
- **Decision:** Custom simplified gRPC protocol (not standard OpenFlow, not Netconf/YANG)
- **Rationale:** Shows protocol design; standard protocols would be harder to implement completely
- **Trade-off:** Not production-standard vs. clearer for portfolio learning

**ADR-0008: Lab-Driven Development**
- **Decision:** Docker Compose as the integration test; everything is deployable and runnable
- **Rationale:** Real code that actually works; easier to validate, easier for others to try
- **Trade-off:** Requires Docker, more operational complexity vs. genuine runnable proof

### Documentation

**`docs/architecture.md`** (500-700 words)
- System overview and reference architecture
- Three layers: foundation, control, fabric
- Data plane vs. control plane separation
- Diagrams: information flow, layer interactions, packet journey through the system

**`docs/integration.md`** (400-500 words)
- How foundation layer (DPDK/eBPF) connects to fabric protocol layer
- How controller orchestrates fabric nodes via southbound API
- How northbound user intent flows through policy engine to device commands
- Sequence diagrams: overlay creation end-to-end

**`docs/foundation.md`** (600-800 words)
- DPDK deep-dive: ring buffers, memory pooling, NIC access patterns
- eBPF deep-dive: XDP hooks, kernel maps, libbpf abstractions
- Performance profiles and benchmarking methodology
- Trade-off analysis: when each is appropriate

**`docs/controller.md`** (700-900 words)
- Northbound API reference (endpoint descriptions, example payloads)
- Southbound protocol specification (message types, state machine)
- Policy engine design: intent-to-config translation
- State management and consistency

**`docs/fabric.md`** (800-1000 words)
- BGP protocol walk-through (state machine, route advertisement, best-path)
- VXLAN encapsulation and tunnel lifecycle
- EVPN route types and integration with BGP/VXLAN
- Protocol state diagrams and message flows

**`docs/quickstart.md`** (200-300 words)
- Prerequisites (Docker, Python 3, Go)
- One-command lab startup: `docker-compose up && ./init.sh`
- First API calls to explore topology
- Traffic generation and metric interpretation
- Common troubleshooting (port conflicts, resource limits)

**`docs/extending.md`** (800-1000 words)
- Catalog of marked extension points
- For each: description, effort estimate (1-3 days / 1-2 weeks), relevant files/functions
- Example: "Add BFD for fast failover" — how controller detects device failure, triggers reroute
- Example: "Implement Segment Routing" — how SR extends BGP, integrates with EVPN

**`README.md`** (300-500 words)
- Portfolio context: what this demonstrates
- Audience: engineers wanting to understand modern networking architecture
- Three learning paths: foundation-first (start with DPDK/eBPF), control-plane-first (start with controller), protocol-first (start with BGP/VXLAN)
- Links to quickstart, architecture doc, ADRs

### MkDocs Site (`mkdocs.yml`)

```yaml
site_name: Chakraview Networking-SDN
theme: material
nav:
  - Home: index.md
  - Architecture:
      - Overview: architecture.md
      - Integration: integration.md
  - Foundation Layer:
      - DPDK: foundation.md#dpdk
      - eBPF: foundation.md#ebpf
      - Benchmarks: foundation.md#benchmarks
  - Control Plane:
      - Controller Design: controller.md
      - APIs: controller.md#apis
  - Fabric Protocols:
      - BGP: fabric.md#bgp
      - VXLAN: fabric.md#vxlan
      - EVPN: fabric.md#evpn
  - Lab:
      - Quick Start: quickstart.md
      - Troubleshooting: quickstart.md#troubleshooting
  - Design:
      - Extension Points: extending.md
      - ADRs:
          - ADR-0001: adrs/ADR-0001-monorepo-architecture.md
          - ADR-0002: adrs/ADR-0002-dpdk-vs-ebpf.md
          - ADR-0003: adrs/ADR-0003-go-control-plane.md
          - ADR-0004: adrs/ADR-0004-bgp-vxlan-evpn.md
          - ADR-0005: adrs/ADR-0005-simulated-fabric.md
          - ADR-0006: adrs/ADR-0006-northbound-apis.md
          - ADR-0007: adrs/ADR-0007-southbound-protocol.md
          - ADR-0008: adrs/ADR-0008-lab-driven-development.md
```

---

## Part 7: Extension Points (Clearly Marked)

All future development areas are marked with `// TODO: EXTEND:` in code or `# TODO: EXTEND:` in Python, with associated comments explaining the extension.

### Foundation Layer Extensions

**DPDK Extensions:**
- Line 45, `vxlan.c`: `// TODO: EXTEND: QoS and traffic shaping — implement token bucket`
- Line 120, `filter.c`: `// TODO: EXTEND: Stateful NAT — connection tracking map`
- Line 200, `forwarding.c`: `// TODO: EXTEND: Load balancing — implement flow hashing across CPU cores`

**eBPF Extensions:**
- Line 60, `xdp.rs`: `// TODO: EXTEND: Tail calls — modularize large programs`
- Line 150, `tc.rs`: `// TODO: EXTEND: Connection tracking — stateful filtering with eBPF maps`

### Controller Extensions

**Policy Engine:**
- `pkg/policy/engine.go:85`: `// TODO: EXTEND: Add BFD integration — detect device failures, trigger reroute`
- `pkg/policy/engine.go:200`: `// TODO: EXTEND: Multi-controller HA — state sync via etcd`

**Storage:**
- `pkg/store/config.go:30`: `// TODO: EXTEND: Persistent storage — replace in-memory with etcd or database`

**Observability:**
- `pkg/northbound/http.go:150`: `// TODO: EXTEND: Prometheus metrics — request latency, device state changes`

### Fabric Layer Extensions

**BGP:**
- `bgp/speaker.py:120`: `# TODO: EXTEND: Segment Routing (SR-MPLS) — add SR TLV to BGP UPDATE`
- `bgp/fsm.py:200`: `# TODO: EXTEND: Route filtering — implement incoming/outgoing route maps`

**VXLAN:**
- `vxlan/learning.py:80`: `# TODO: EXTEND: EVPN-based MAC learning — replace flooding with route-based lookup`
- `vxlan/tunnel.py:150`: `# TODO: EXTEND: Tunnel redundancy — active-active or active-backup modes`

**EVPN:**
- `evpn/integration.py:200`: `# TODO: EXTEND: EVPN services — implement E-LAN, E-Line, IP-VPN`
- `evpn/routes.py:300`: `# TODO: EXTEND: Multicast — handle BUM (broadcast, unknown-unicast, multicast) trees`

### Lab Extensions

**Scale Testing:**
- `lab/scripts/traffic.py:500`: `# TODO: EXTEND: Large fabric scale test — 100+ devices, 1000+ routes`

**Failure Injection:**
- `lab/scripts/init.sh:200`: `# TODO: EXTEND: Chaos engineering — link failures, controller restart, device crashes`

**Real Hardware:**
- `lab/docker-compose.yml`: `# TODO: EXTEND: Run fabric nodes on real switches (Cumulus, etc.)`

---

## Acceptance Criteria & Validation

### Code Completeness
- [ ] All three layers implemented and runnable
- [ ] DPDK and eBPF both working, benchmarked
- [ ] Controller with REST and gRPC APIs
- [ ] BGP, VXLAN, EVPN protocol logic implemented
- [ ] Lab spins up end-to-end, no manual steps beyond `docker-compose up`

### Documentation
- [ ] 8 ADRs written, committed
- [ ] Architecture, integration, foundation, controller, fabric docs complete
- [ ] Quickstart guide tested (someone can follow it and get lab running)
- [ ] Extending guide lists all marked extension points
- [ ] MkDocs site builds and deploys (e.g., GitHub Pages)

### Lab & Testing
- [ ] Traffic generation and validation scripts work
- [ ] Metrics collection shows DPDK vs. eBPF performance comparison
- [ ] Overlay creation, BGP route distribution, VXLAN encapsulation all validated
- [ ] Lab can be torn down and recreated cleanly

### Quality
- [ ] Code is well-commented, especially around extension points
- [ ] No TODOs except marked `EXTEND:` sections
- [ ] Type hints in Python, proper error handling in Go/C
- [ ] CI/CD configured (GitHub Actions: build, test, lint)

---

## Summary

This design specifies a three-layer networking SDN portfolio project with:
- **Foundation:** DPDK vs. eBPF packet processing implementations with head-to-head benchmarks
- **Control Plane:** Go SDN controller with intent-based north/south APIs
- **Fabric Protocols:** Python implementations of BGP, VXLAN, EVPN showing protocol evolution
- **Integration:** Docker Compose lab where all three layers work together end-to-end
- **Documentation:** 8 ADRs, comprehensive guides, quickstart, and clearly marked extension points for future development

Equal depth across layers, hybrid implementation (full foundation + controller, prototypes for fabric), and everything runnable and testable.
