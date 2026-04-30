# Quick Start Guide

## Prerequisites

- Docker & Docker Compose
- Go 1.21+
- Python 3.11+
- Rust (for eBPF toolchain)

## Local Development (No Containers)

### 1. Build Foundation Layer

```bash
cd foundation/dpdk
make clean && make
./dpdk-handler
```

Expected output:
```
DPDK Handler Starting
Forwarding decision: egress_port=1
VXLAN encapsulation: OK
VXLAN decapsulation: OK
```

### 2. Build Controller

```bash
cd controller
go mod tidy
go test ./...
go build -o sdn-controller ./cmd/sdn-controller
./sdn-controller
```

Expected output:
```
SDN Controller Starting
Topology: 0 devices, 0 links
gRPC server listening on 0.0.0.0:9090
REST API server listening on 0.0.0.0:8080
```

### 3. Build Fabric Protocols

```bash
cd fabric
pip install -r requirements.txt
python -m pytest -v
```

Expected output:
```
fabric/bgp/test_fsm.py::test_state_transitions PASSED
fabric/vxlan/test_tunnel.py::test_encapsulation PASSED
fabric/evpn/test_routes.py::test_mac_ip_route PASSED
```

## Docker Lab Execution

### 1. Start Lab

```bash
cd lab
cp .env.example .env
docker-compose up -d
```

### 2. Initialize Topology

```bash
bash lab/scripts/init.sh
```

Expected output:
```
Initializing SDN Lab...
Waiting for controller to be ready...
Controller is ready!
Registering network devices...
Device registration complete
Verifying topology...
```

### 3. Query Topology

```bash
curl http://localhost:8080/api/v1/topology
curl http://localhost:8080/api/v1/topology/devices
```

Example response:
```json
{
  "status": "ok",
  "summary": "Topology: 4 devices, 0 links",
  "devices": 4,
  "links": 0
}
```

### 4. Stop Lab

```bash
docker-compose down
```

## Testing

Run end-to-end tests (requires running lab):
```bash
python -m pytest tests/e2e_test.py -v
bash tests/integration_test.sh
```

## Next Steps

1. **Explore APIs:** Use `curl` to query topology endpoints
2. **Add Devices:** Modify `lab/scripts/register-devices.sh`
3. **Create Policies:** Use REST API to define network intents
4. **Trace Packets:** Enable debug logging in controller
5. **Study Implementation:** Read ADRs in `docs/adrs/`
