# Chakraview Networking-SDN Architecture

## Overview

Three-layer architecture for SDN portfolio project:

```
┌─────────────────────────────────────────────┐
│         External Clients (REST API)         │
│  curl http://localhost:8080/api/v1/topology│
└─────────────────────┬───────────────────────┘
                      │
┌─────────────────────┴────────────────────┐
│     SDN Controller (Go, Port 8080)       │
│  ┌──────────────────────────────────┐   │
│  │ Topology Service                 │   │
│  │ - Device registration            │   │
│  │ - Graph-based reachability       │   │
│  │ - Discovery event handlers       │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ Policy Engine                    │   │
│  │ - Intent-to-config translation   │   │
│  │ - ACL and rule management        │   │
│  └──────────────────────────────────┘   │
└─────────────┬────────────────────────────┘
              │ gRPC (Port 9090)
              │
┌─────────────┴────────────────────────────┐
│   Fabric Nodes (Python Simulation)       │
│  ┌──────────────────────────────────┐   │
│  │ BGP Speaker                      │   │
│  │ - FSM with 6 states (IDLE...EST) │   │
│  │ - Route learning & advertisement │   │
│  │ - Peer management                │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ VXLAN Tunnel Manager             │   │
│  │ - Tunnel creation/deletion       │   │
│  │ - Packet encapsulation           │   │
│  │ - MAC learning table             │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ EVPN Route Manager               │   │
│  │ - Type 2 (MAC/IP) routes         │   │
│  │ - Type 5 (IP Prefix) routes      │   │
│  │ - RIB management                 │   │
│  └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
                      │
┌─────────────────────┴────────────────────┐
│    Foundation Layer (C + Rust)           │
│  ┌──────────────────────────────────┐   │
│  │ DPDK Forwarding Engine (User)   │   │
│  │ - L2/L3 packet processing       │   │
│  │ - Longest-prefix-match routing  │   │
│  │ - VXLAN encap/decap             │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ eBPF XDP Program (Kernel)       │   │
│  │ - In-kernel packet processing   │   │
│  │ - BPF maps for routes, tunnels  │   │
│  │ - Statistics collection         │   │
│  └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

## Data Flow Example

### Device Registration
1. Fabric node calls gRPC `RegisterDevice()`
2. Controller adds to topology graph
3. Discovery service emits `device.registered` event
4. Topology becomes queryable via REST `/api/v1/topology/devices`

### Route Advertisement
1. BGP speaker learns route from peer
2. gRPC `AdvertiseBgpRoute()` to controller
3. Policy engine translates to forwarding rules
4. Foundation layer (DPDK/eBPF) installs rules
5. Packets forwarded per installed rules

## Technology Stack

| Layer | Component | Language | Port |
|-------|-----------|----------|------|
| Control | SDN Controller | Go | 8080 (REST), 9090 (gRPC) |
| Fabric | BGP/VXLAN/EVPN | Python | gRPC client |
| Foundation | DPDK | C | Userspace |
| Foundation | eBPF | Rust + C | Kernel |
| Lab | Docker Compose | YAML | Local |

## Extensibility

- **Add Protocol:** Implement gRPC handler in controller, Python client in fabric node
- **Add Device Type:** Extend NetworkDevice class with custom role behavior
- **Add Policies:** Define new PolicyIntent types, translators in policy engine
- **Add Foundation Layer:** Parallel user/kernel implementations compared
