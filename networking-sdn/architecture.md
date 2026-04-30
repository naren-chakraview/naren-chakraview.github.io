# Chakraview Networking-SDN Architecture

## Overview

Three-layer architecture for SDN portfolio project:

```mermaid
graph TD
    subgraph "Northbound Interface"
        EXTERNAL["External Clients<br/>REST API<br/>:8080"]
    end
    
    subgraph "Control Plane"
        TOPO["Topology Service<br/>Device registration<br/>Graph + BFS path finding<br/>Discovery events"]
        INTENT["Intent Engine<br/>Request validation<br/>Intent-to-config translation"]
        subgraph CTRL["SDN Controller (Go)"]
            TOPO
            INTENT
        end
    end
    
    subgraph "Fabric Layer"
        BGP["BGP Speaker<br/>FSM: Idle→Establish<br/>Route learning<br/>Peer management"]
        VXLAN["VXLAN Manager<br/>Tunnel creation<br/>Encap/Decap<br/>MAC learning"]
        EVPN["EVPN Handler<br/>Type 2: MAC/IP<br/>Type 5: IP Prefix<br/>Route distribution"]
        subgraph FABRIC["Fabric Nodes (Python)"]
            BGP
            VXLAN
            EVPN
        end
    end
    
    subgraph "Foundation Layer"
        DPDK["DPDK Agent (C)<br/>User-space forwarding<br/>LPM routing<br/>VXLAN encap/decap"]
        EBPF["eBPF Agent (Rust)<br/>XDP hook<br/>BPF maps<br/>In-kernel processing"]
        subgraph FOUND["Packet Processing"]
            DPDK
            EBPF
        end
    end
    
    subgraph "Southbound Interface"
        GRPC["gRPC Southbound<br/>:50051<br/>SetRoutes, SetTunnels<br/>GetStats streaming"]
    end
    
    EXTERNAL -->|REST| INTENT
    INTENT -->|path computation| TOPO
    INTENT -->|check state| TOPO
    TOPO -->|device updates| INTENT
    
    CTRL -->|gRPC| GRPC
    GRPC -->|calls| FABRIC
    GRPC -->|calls| FOUND
    
    FABRIC -->|BGP peers<br/>TCP :179| FABRIC
    FABRIC -->|VXLAN tunnels<br/>UDP :4789| FABRIC
    
    style CTRL fill:#2196F3,color:#fff
    style FABRIC fill:#9C27B0,color:#fff
    style FOUND fill:#4CAF50,color:#fff
    style EXTERNAL fill:#FF9800,color:#fff
    style GRPC fill:#F44336,color:#fff
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
