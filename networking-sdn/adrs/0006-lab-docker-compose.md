# ADR-0006: Lab Environment — Docker Compose for End-to-End Testing

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

A portfolio project must be **runnable**: viewers should be able to `docker-compose up` and see the system working, not study code in isolation.

The lab requires:
- Controller running and accepting gRPC connections
- DPDK and eBPF agents started, registering with controller
- Simulated fabric devices with BGP/VXLAN/EVPN
- Traffic generator to send packets through the system
- Health checks to verify all components started correctly

The lab must be:
- **Reproducible**: Same compose file works on Linux, Mac, Windows (WSL)
- **Debuggable**: Logs from each component visible; services can be restarted independently
- **Comprehensive**: Shows the full three-layer stack (foundation agents, controller, fabric devices)
- **Fast**: Startup under 30 seconds; viewers don't wait

---

## Decision

Use **Docker Compose** as the lab orchestration tool. Each layer gets one or more services:

| Service | Image | Role |
|---------|-------|------|
| `sdn-controller` | Go binary | SDN controller with REST API + gRPC listener |
| `dpdk-agent` | DPDK C app | Foundation layer: DPDK forwarding engine |
| `ebpf-agent` | Rust/eBPF binary | Foundation layer: eBPF XDP program loader |
| `fabric-node-1`, `-2`, `-3` | Python app | Fabric layer: simulated devices with BGP/VXLAN/EVPN |
| `traffic-gen` | tcpdump/iperf wrapped | Generate synthetic traffic to test forwarding |

All services share a custom Docker network (`sdn-net`) so they can reach each other by hostname. Controller listens on `:8080` (REST) and `:50051` (gRPC). Each agent connects back to controller on startup.

**Health check pattern:**
Each service includes a `healthcheck` that validates its readiness:
- Controller: HTTP `GET /api/v1/health` returns 200
- Agents: TCP connect to `:50051` succeeds
- Fabric nodes: BGP peers establish connections

Compose waits for health checks before declaring `docker-compose up` complete.

---

## Consequences

**Positive:**
- **One-command startup**: `docker-compose up -d` starts all nine services in correct order (depends_on enforces)
- **Visibility**: `docker-compose logs -f` streams output from all services; `docker-compose exec sdn-controller bash` for debugging
- **Reproducibility**: Same compose file works everywhere; no manual port configuration or firewall rules
- **Educational clarity**: Viewers can inspect docker-compose.yml to understand system topology and dependencies
- **Fast iteration**: Change a source file, rebuild image, restart service — all without touching other services

**Negative:**
- **Docker dependency**: Requires Docker/Docker Desktop; cannot run bare-metal on Linux without container runtime
- **Resource overhead**: Nine containers + custom network add ~500MB memory overhead
- **Image build time**: First startup requires building C/Rust binaries; ~2-3 minutes
- **Networking simulation**: All services can reach each other; no packet loss or latency simulation (acceptable for portfolio)

---

## Constraints

- Controller and agents communicate in-container on Docker network; external exposure via port mappings only for REST API (`:8080`)
- BGP sessions between fabric devices are direct (TCP `:179`); no BGP route reflectors
- Traffic generator is simple `iperf3` client → server; not a real traffic generation tool

---

## When This Choice Stops Being Correct

If the lab must simulate network failure conditions (packet loss, latency jitter, link failure), Docker Compose alone is insufficient. Add `tc` (traffic control) or `Toxiproxy` to inject failures.

If the lab must scale to 100+ devices, Docker Compose becomes unwieldy; use Kubernetes with StatefulSets or Terraform for infrastructure-as-code.

---

## Alternatives Considered

**Kubernetes (minikube/kind)**  
Native service discovery, load balancing, declarative scaling. Rejected because Kubernetes is complex; viewers unfamiliar with K8s would struggle to understand the lab. Docker Compose is simpler.

**Manual container startup (docker run)**  
Full control, no abstraction. Rejected because without orchestration, connecting N containers correctly is tedious; port conflicts and service startup order become error-prone.

**Vagrant + Virtualbox**  
Bare-metal VMs, closer to production. Rejected because Vagrant is slower than containers and adds complexity; Docker Compose's simplicity is better for learning.

**Terraform for infrastructure**  
Infrastructure-as-code, cloud-native. Rejected because portfolio is self-contained; deploying to AWS/GCP adds scope creep.

---

## Related

- [ADR-0001](0001-architecture.md) — Lab implements the three-layer architecture end-to-end
- [ADR-0003](0003-grpc-southbound.md) — gRPC protocol that lab exercises
- `/lab/docker-compose.yml` — Actual service definitions
- `/lab/scripts/init.sh` — Health check and initialization script
