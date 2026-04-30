# ADR-0002: Foundation Layer — DPDK vs eBPF Comparison

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

Packet processing is the foundation of any SDN system. Two mature approaches exist:

1. **DPDK (Data Plane Development Kit)** — A userspace library that bypasses the kernel, grabs NICs directly, and processes packets in tight polling loops. Developed by Intel, used in production by Telcos, Cloud providers (AWS). Provides **full control**: custom packet headers, complex forwarding logic, direct NIC management.

2. **eBPF (extended Berkeley Packet Filter)** — A kernel virtual machine that can be attached to kernel networking hooks (XDP, TC). Developed by the Linux community, becoming the standard for cloud-native networking (Cilium, Calico, io_uring). Provides **kernel integration**: no userspace copies, kernel scheduling, attestation via verifier.

The portfolio cannot choose one: each teaches different engineering lessons. DPDK teaches systems-level performance optimization; eBPF teaches how to extend the kernel safely. A professional engineer must understand both and know when to choose each.

---

## Decision

Implement **both DPDK (in C) and eBPF (in Rust)** as separate, equivalent implementations in the foundation layer. The controller can dispatch traffic to either implementation; the lab can compare their behavior.

**DPDK implementation:**
- LPM routing engine with 1000 routes, 500 filter rules
- VXLAN encapsulation/decapsulation
- Forwarding statistics
- Single-threaded polling loop (educational simplicity)

**eBPF implementation:**
- XDP hook attachment to interface
- BPF maps for routing table, statistics, tunnel state
- Verifier-safe packet inspection and modification
- Kernel scheduler handles concurrency

Both implementations expose the same gRPC interface to the controller: `RegisterAgent`, `SetRoutes`, `SetTunnels`, `QueryStats`.

---

## Consequences

**Positive:**
- **Educational depth**: Learners see the full spectrum from user-space (DPDK) to kernel (eBPF); understand when each is appropriate
- **Comparative benchmarking**: Lab can measure latency, throughput, CPU utilization of each approach under identical traffic loads
- **Production relevance**: Both are real technologies used in production (DPDK in Telcos, eBPF in Kubernetes networking)
- **Integration learning**: Viewers see how to integrate heterogeneous components; real networks often mix technologies

**Negative:**
- **Maintenance burden**: Two distinct stacks (C with PMDs, Rust with libbpf) require different tooling, test harnesses, and profiling approaches
- **Not apples-to-apples**: DPDK runs isolated in userspace; eBPF runs alongside kernel networking. Performance comparison is complex (CPU cost, memory overhead, latency variance)
- **Scope creep risk**: Temptation to add advanced features to one implementation (NUMA awareness, multicore scaling) that wouldn't exist in the other

---

## Constraints

- DPDK implementation is single-threaded polling loop: demonstrates the technology but not production scalability
- eBPF implementation is XDP-only (no TC/Netfilter hooks): sufficient for layer 2/3 forwarding, not for application-layer visibility
- Neither is expected to handle >10M packets/second (lab traffic is synthetic)

---

## When This Choice Stops Being Correct

If the portfolio pivots to production SDN (not educational), consolidate to eBPF. eBPF is the industry direction for cloud-native networking: it is safe, kernel-integrated, and does not require dedicated NICs.

---

## Alternatives Considered

**DPDK only**  
Simpler codebase, focuses depth on one technology. Rejected because eBPF is increasingly important in cloud-native environments; omitting it would make the portfolio incomplete for modern deployments.

**eBPF only**  
Modern and kernel-integrated. Rejected because DPDK's direct hardware control teaches systems-level lessons that eBPF's sandbox model obscures. Production Telcos still rely on DPDK.

**OVS (Open vSwitch)**  
Production packet switch, built-in forwarding logic. Rejected as a single opaque component; learners cannot understand its internals or extend it. This portfolio is about teaching, not deploying OVS.

---

## Related

- [ADR-0001](0001-architecture.md) — Three-layer architecture that frames this choice
- [ADR-0003](0003-grpc-southbound.md) — Southbound interface that both implementations expose
- Lab `/foundation/dpdk/` and `/foundation/ebpf/` directories for implementation details
