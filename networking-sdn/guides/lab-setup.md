# Lab Setup Guide — Running the Complete System

## Overview

The lab orchestrates all three layers (foundation, controller, fabric) in a Docker Compose environment. This guide walks you through starting, testing, and debugging the lab.

## Quick Start

```bash
cd lab
docker-compose up -d
docker-compose ps
```

Check that all services are healthy:

```bash
docker-compose logs --follow
```

Wait for messages like:
```
sdn-controller | INFO Server listening on :8080
fabric-node-1 | INFO BGP peer established with fabric-node-2
```

## Service Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Docker Compose Network (sdn-net)                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌────────────────┐  ┌────────────┐ │
│  │ sdn-         │  │ dpdk-agent     │  │ ebpf-agent │ │
│  │ controller   │  │ (foundation)   │  │(foundation)│ │
│  │ (Go, port    │  │                │  │            │ │
│  │ 8080/50051)  │  │ Registers with │  │ Registers  │ │
│  │              │  │ controller     │  │ with ctrl  │ │
│  │ Listens:     │  └────────────────┘  └────────────┘ │
│  │ REST :8080   │                                      │
│  │ gRPC :50051  │  ┌──────────────┐  ┌──────────────┐ │
│  └──────────────┘  │ fabric-node-1│  │ fabric-node-2│ │
│         ↑          │ (Python, BGP)│  │ (Python, BGP)│ │
│    accepts         └──────────────┘  └──────────────┘ │
│    routes via         BGP Peers          BGP Peers   │
│    REST API           gRPC client        gRPC client │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ traffic-gen (iperf3 client/server)           │   │
│  │ Generates synthetic traffic for testing      │   │
│  └──────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Services

**sdn-controller**
- Listens on `:8080` (REST API)
- Listens on `:50051` (gRPC for agents)
- Manages topology, handles intent requests
- Health check: `curl localhost:8080/api/v1/health`

**dpdk-agent**
- Implements DPDK forwarding engine
- Registers with controller on startup
- Exposes gRPC interface for route/tunnel updates
- Health check: TCP `:50051` responds

**ebpf-agent**
- Loads eBPF XDP program
- Registers with controller on startup
- Health check: TCP `:50051` responds

**fabric-node-1, fabric-node-2, fabric-node-3**
- Python simulated switches
- Establish BGP peering with each other
- Register with controller
- Health check: Can connect to BGP port `:179`

**traffic-gen**
- iperf3 server listening on `:5201`
- Optional: iperf3 client to generate traffic
- Tests end-to-end forwarding

## Configuration

Edit `lab/.env.example` to customize:

```bash
# .env.example
DPDK_AGENT_IP=dpdk-agent
EBPF_AGENT_IP=ebpf-agent
CONTROLLER_IP=sdn-controller
FABRIC_NODE_1_IP=fabric-node-1
FABRIC_NODE_2_IP=fabric-node-2
FABRIC_NODE_3_IP=fabric-node-3
```

Pass environment variables to compose:

```bash
export DPDK_AGENT_IP=my-host
docker-compose up -d
```

## Testing Workflows

### 1. Verify Services Started

```bash
docker-compose ps
# All services should show "Up" and healthy
```

### 2. Check Topology Discovery

```bash
curl -s http://localhost:8080/api/v1/topology | jq .
```

Expected response:
```json
{
  "devices": [
    {"id": "dpdk-agent", "ip": "10.0.0.1", "capabilities": ["ipv4-forwarding"]},
    {"id": "ebpf-agent", "ip": "10.0.0.2", "capabilities": ["ipv4-forwarding"]},
    {"id": "fabric-node-1", "ip": "10.0.0.3", "capabilities": ["bgp", "vxlan"]},
    ...
  ],
  "links": [...]
}
```

### 3. Query Device Statistics

```bash
curl -s http://localhost:8080/api/v1/health | jq .
```

Check packet counts and tunnel state.

### 4. Install a Route (Intent)

```bash
curl -X POST http://localhost:8080/api/v1/routes \
  -H "Content-Type: application/json" \
  -d '{
    "source_subnet": "10.1.0.0/24",
    "dest_subnet": "10.2.0.0/24",
    "tunnel_id": 1,
    "priority": 100
  }'
```

This triggers the controller to compute paths and install routes on all affected devices.

### 5. Generate Traffic

```bash
# Inside fabric-node-1 container, send packets
docker-compose exec fabric-node-1 bash
# (Inside container)
ping 10.2.0.1  # Should succeed if routes installed
```

Or use iperf3:

```bash
# Terminal 1: Start iperf3 server (should already be running)
docker-compose exec traffic-gen iperf3 -s

# Terminal 2: Generate traffic
docker-compose exec traffic-gen iperf3 -c traffic-gen -t 10
# Runs 10-second traffic flow; check packet counts with curl
```

## Debugging

### Check Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs sdn-controller
docker-compose logs fabric-node-1

# Follow in real-time
docker-compose logs -f fabric-node-1
```

### Inspect Topology in Controller

```bash
docker-compose exec sdn-controller bash
# (Inside container)
curl localhost:8080/api/v1/topology | jq .
```

### Check BGP Session State

```bash
docker-compose exec fabric-node-1 bash
# (Inside container)
python -c "from device import NetworkDevice; d = NetworkDevice('node1', 65001); print(d.bgp_speaker.state)"
```

### Trace gRPC Calls

Enable gRPC debug logging:

```bash
GRPC_VERBOSITY=debug GRPC_TRACE=all docker-compose up sdn-controller
```

This prints all gRPC messages. Useful for debugging agent registration failures.

### Restart a Service

```bash
docker-compose restart fabric-node-1
# Service restarts; registers with controller again
```

### Rebuild Images

If you modify source code:

```bash
docker-compose build sdn-controller
docker-compose up -d sdn-controller
```

Or rebuild all:

```bash
docker-compose build --no-cache
docker-compose up -d
```

## Performance Testing

### Throughput Test

```bash
# Generate 10 seconds of traffic
docker-compose exec traffic-gen iperf3 -c traffic-gen -t 10 -P 4

# Check packet counts
curl http://localhost:8080/api/v1/health | jq '.devices[0].stats'
```

Expected results:
- **DPDK agent**: ~100K packets/second
- **eBPF agent**: ~1M packets/second (kernel fast path)
- **Fabric devices**: ~50K packets/second (Python overhead)

### Latency Test

```bash
# Ping test (shows round-trip latency)
docker-compose exec fabric-node-1 ping -c 100 fabric-node-2
# Average latency should be <5ms in Docker

# For per-packet latency, inspect timestamps in controller logs
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Services stuck in "starting" state | Check service logs: `docker-compose logs`. Build may have failed. |
| Health checks fail | Ensure port mappings are correct in docker-compose.yml. |
| Agents can't reach controller | Check docker-compose network: `docker network ls` and verify service names in docker-compose.yml |
| BGP peers don't establish | Check fabric node logs for peer configuration errors. Verify IP addresses and ASN assignments. |
| Routes not installed on devices | Check controller logs for intent validation errors. Verify subnet addresses are reachable. |
| Traffic doesn't flow | Check topology: are all devices connected? Run `curl http://localhost:8080/api/v1/topology` |

## Stopping the Lab

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (data loss)
docker-compose down -v

# Stop specific service
docker-compose stop fabric-node-1
```

## Next Steps

- [Testing and Extending](../extending/custom-protocols.md) — Modify fabric protocols
- [ADR-0006: Lab Architecture](../adrs/0006-lab-docker-compose.md) — Design decisions
- [Controller Guide](controller-layer.md) — Understanding the control plane
