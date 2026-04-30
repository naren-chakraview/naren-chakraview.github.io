# Chakraview Networking-SDN

A comprehensive portfolio project showcasing modern networking and SDN concepts.

## What's Inside?

**Foundation Layer** - High-performance packet processing:
- DPDK forwarding engine with L2/L3 logic
- eBPF XDP program for kernel-space processing
- Comparative analysis of user vs kernel space approaches

**SDN Controller** - Intent-based network orchestration (Go):
- Topology service with graph-based reachability
- Northbound REST API for external clients
- Southbound gRPC protocol for device communication
- Policy engine for intent-to-config translation

**Fabric Protocols** - Routing and overlay networking (Python):
- BGP speaker with RFC 4271 FSM
- VXLAN tunnel management with MAC learning
- EVPN route types (MAC/IP, IP Prefix)
- Simulated network device model

**Lab Integration** - Docker Compose sandbox:
- One-command lab startup
- Device registration and topology verification
- End-to-end integration tests

## Quick Start

### Local Build
```bash
make build
make test
```

### Docker Lab
```bash
cd lab && docker-compose up -d
bash scripts/init.sh
curl http://localhost:8080/api/v1/topology
```

## Documentation

- [Architecture Overview](architecture.md) - System design and data flows
- [Quick Start Guide](quickstart.md) - Local and Docker setup
- [Architecture Decisions](adrs/0001-architecture.md) - Design rationale
- [Extending the System](extending/custom-protocols.md) - Add your own protocols

## Technology Stack

| Layer | Tech | Purpose |
|-------|------|---------|
| Control | Go + gRPC | SDN controller |
| Fabric | Python | BGP, VXLAN, EVPN |
| Foundation | C + Rust | DPDK, eBPF |
| Lab | Docker | Containerized execution |

## Project Status

- Phase 1: Project structure ✅
- Phase 2: DPDK forwarding + VXLAN ✅
- Phase 3: eBPF skeleton ✅
- Phase 4: SDN controller ✅
- Phase 5: Fabric protocols ✅
- Phase 6: Lab & docs ✅

All tasks complete. Ready for exploration and extension!
