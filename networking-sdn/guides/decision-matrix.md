# Decision Matrix — Key Architectural Choices

This guide summarizes the major architectural decisions in the networking-sdn portfolio and the tradeoffs that led to each choice.

## 1. Three-Layer Architecture

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **Abstraction Levels** | Foundation (packet processing), Control (intent), Fabric (protocols) | Monolithic single app | Shows each concern independently; mirrors real SDN deployments |
| **Foundation Tech** | Both DPDK and eBPF | DPDK only | Demonstrates spectrum from userspace to kernel; both used in production |
| **Control Plane Language** | Go + gRPC | Python, Rust, or Hybrid | Fast iteration, strong typing, excellent gRPC support |
| **Fabric Implementation** | Python simulated devices | Real switches or GoBGP | Simple to understand and extend; no vendor licensing |

**See:** [ADR-0001](../adrs/0001-architecture.md), [ADR-0002](../adrs/0002-dpdk-vs-ebpf.md)

## 2. Packet Processing Foundation

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **DPDK Approach** | Single-threaded polling loop | Multicore with NUMA | Teaches fundamentals without systems complexity |
| **eBPF Approach** | XDP hook only | XDP + TC (Netfilter) | XDP is the fast path; TC adds complexity without educational benefit |
| **API Consistency** | Both expose same gRPC interface | Different APIs per impl | Lab can swap implementations; controller unchanged |
| **Performance Target** | 100K pps (DPDK), 1M pps (eBPF) | Production-grade (10M+) | Educational clarity > raw throughput |

**See:** [ADR-0002](../adrs/0002-dpdk-vs-ebpf.md), [ADR-0008](../adrs/0008-performance-constraints.md), [Foundation Guide](foundation-layer.md)

## 3. Southbound Protocol

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **Protocol** | gRPC for agents, REST for operators | REST for both, AMQP queue | gRPC efficiency internal; REST human-friendly external |
| **Data Format** | Protocol Buffers (protobuf) | JSON, XML | Type safety; binary efficiency; cross-language code generation |
| **Connection Model** | Persistent gRPC streams | Polling REST endpoints | Server-side streaming allows devices to push stats asynchronously |
| **Authentication** | Self-signed certificates (lab) | Mutual TLS in production | Simplicity for portfolio; marked as EXTENSION for real deployment |

**See:** [ADR-0003](../adrs/0003-grpc-southbound.md), [Controller Guide](controller-layer.md)

## 4. Controller Architecture

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **Discovery** | gRPC device registration | Automatic LLDP/ARP learning | Explicit is clearer for education; automatic adds L2 complexity |
| **Path Computation** | BFS (breadth-first search) | Dijkstra, CSPF | BFS sufficient for equal-cost links; simpler algorithm to teach |
| **State Storage** | In-memory graph + lock | Database (etcd, PostgreSQL) | In-memory sufficient for 1K devices; persistence marked as EXTENSION |
| **Failure Handling** | Simple retry | Rollback with transaction | Rollback adds complexity; retry acceptable for lab |

**See:** [ADR-0004](../adrs/0004-go-controller-design.md), [Controller Guide](controller-layer.md)

## 5. Fabric Protocols

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **Primary Routing** | BGP | OSPF, IS-IS, custom | BGP most common in cloud; 13-state FSM is interesting; external routing protocol |
| **Overlay Tunneling** | VXLAN | Geneve, STT | VXLAN standard in datacenter; simpler encapsulation than Geneve |
| **Multi-Device Coordination** | EVPN (Type 2, Type 5 routes) | Static configuration, LISP | EVPN the industry direction; Type 2+5 cover common cases; Types 1,3,4 marked EXTENSION |
| **Device Simulation** | Python classes | Real hardware emulation (QEMU) | Simplicity; Python allows rapid iteration; no hardware emulation overhead |

**See:** [ADR-0005](../adrs/0005-bgp-vxlan-evpn.md), [Fabric Guide](fabric-layer.md)

## 6. Lab Orchestration

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **Orchestration** | Docker Compose | Kubernetes, Vagrant, manual | Docker Compose simplest for portfolio; Kubernetes overkill; manual error-prone |
| **Networking** | Custom bridge network | Host network, Macvlan | Bridge network isolated; Macvlan adds complexity |
| **Health Checks** | Container healthcheck + init script | Polling endpoints | Healthcheck native; init script coordinates startup order |
| **Traffic Generation** | iperf3 | tcpdump wrapper, dedicated tool | iperf3 standard, sufficient for synthetic load |

**See:** [ADR-0006](../adrs/0006-lab-docker-compose.md), [Lab Guide](lab-setup.md)

## 7. Repository Structure

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **Organization** | Monorepo (one git repo) | Polyrepo (git submodules) | Single clone = full system; no version coordination overhead |
| **Versioning** | All layers version together | Independent per-layer | Simplicity; all release as v1.0.0 together |
| **Build System** | Root Makefile + layer Makefiles | Gradle, Bazel, single Makefile | Hierarchical Make; each layer independent; no shared abstraction |
| **Dependency Management** | Per-language (go.mod, Cargo.toml, requirements.txt) | Shared lock file | Clear boundaries; per-language tools are the standard |

**See:** [ADR-0007](../adrs/0007-monorepo-structure.md)

## 8. Performance Constraints

| Aspect | Choice | Alternative | Why |
|--------|--------|-------------|-----|
| **Optimization Target** | Educational clarity | Production performance | Code readability > throughput; marked EXTENSIONS for perf improvements |
| **Concurrency Model** | Single-threaded (DPDK), kernel scheduling (eBPF), GoroutinesGo) | Multicore with locks | Complexity hidden by language/OS; suitable for portfolio scope |
| **Caching** | None (compute on demand) | Memoization, LRU cache | Small networks; cache invalidation complexity not worth it |
| **Monitoring** | Prometheus metrics + structured logs | Full APM (DataDog, NewRelic) | Metrics sufficient for understanding behavior; APM overkill |

**See:** [ADR-0008](../adrs/0008-performance-constraints.md)

## Tradeoff Summary

**What We Optimized For:**
- **Education**: Code clarity, understandability, teachable complexity
- **Deployability**: Docker Compose `docker-compose up` works out-of-box
- **Completeness**: Full three-layer system in single lab

**What We De-Optimized:**
- **Performance**: Modest throughput (100K-1M pps) vs. production (10M+ pps)
- **Scalability**: 1K devices max vs. production (100K+)
- **Reliability**: Simple retry vs. proper transactions and rollback
- **Security**: Self-signed certs vs. PKI infrastructure

This is appropriate for a portfolio project. If goals change (production SDN, benchmarking), revisit these decisions.

## Future Optimization Roadmap

These improvements are marked throughout the codebase with `EXTENSION:` comments:

1. **Multicore DPDK** — Replace single polling loop with thread pool per core
2. **TC (Traffic Control) in eBPF** — Egress filtering for traffic shaping
3. **BGP Route Dampening** — Suppress routes that flap frequently
4. **Persistent Controller State** — etcd or PostgreSQL for topology recovery
5. **Transaction-based Intent** — Rollback when route installation fails midway
6. **Performance Benchmarking** — Comparative benchmarks DPDK vs eBPF at scale
7. **eBPF Ring Buffer Telemetry** — Real-time event streaming instead of counter polling
8. **EVPN Type 3 (Inclusive Multicast)** — Support broadcast/multicast overlays

## Related Documents

- [Architecture Overview](../architecture.md)
- [8 ADRs](../adrs/) — Detailed rationale for each decision
- [Component Guides](.) — Foundation, Controller, Fabric, Lab
