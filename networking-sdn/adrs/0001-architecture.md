# ADR-0001: Three-Layer SDN Architecture

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

A portfolio project demonstrating modern Software-Defined Networking (SDN) requires showcasing three distinct architectural concerns simultaneously:

1. **Packet Processing** — raw forwarding performance and the engineering tradeoff between user-space (DPDK) and kernel-space (eBPF) packet processing
2. **Network Control** — how intent flows from administrators through a controller to network devices, including API design and state management
3. **Fabric Protocols** — how distributed network devices reach consensus on routing state, overlay tunnels, and service placement

A single technology stack (e.g., pure kernel eBPF or pure user-space DPDK) obscures the educational value: an engineer learns DPDK but not eBPF's kernel integration, or learns one protocol but not how it integrates with a controller.

The portfolio must be deployable end-to-end (Docker Compose) so viewers can spin up a lab, send traffic, and observe how intent → control → data plane decisions → packet forwarding.

---

## Decision

Adopt a **three-layer architecture** with deliberate separation of concerns:

| Layer | Component | Technology | Responsibility |
|-------|-----------|-----------|---|
| **Foundation** | Packet Processing | DPDK (C) + eBPF (Rust) | User-space and kernel forwarding; LPM routing; VXLAN encapsulation |
| **Control** | SDN Controller | Go + gRPC | Topology discovery; path computation; device management; intent northbound API |
| **Fabric** | Protocol Plane | Python | BGP speaker, VXLAN overlay, EVPN route handling; simulated devices |

Each layer is independently testable and can be developed, understood, and iterated separately. Foundation handles packets; Controller handles intent and state; Fabric handles consensus.

---

## Consequences

**Positive:**
- **Educational clarity**: Each layer teaches a distinct skill (kernel vs userspace packet processing, control plane design, distributed protocol implementation)
- **Technology freedom**: Go for speed, Python for prototyping, C for performance — each chosen deliberately, not by accident
- **Modular integration**: Lab can mix real DPDK, real eBPF, and simulated fabric; can replace any layer independently
- **Portfolio strength**: Demonstrates mastery of multiple paradigms (systems, distributed systems, protocol design) not just one
- **Extensibility**: Clear extension points marked in code for adding more devices, protocols, or optimizations

**Negative:**
- **Operational complexity**: Three distinct toolchains (C, Rust, Go, Python) require different build tools, testing approaches, and deployment models
- **Performance not unified**: DPDK, eBPF, and Python gRPC have different latency/throughput characteristics; no single "optimal" path through the stack
- **Learning curve**: Viewers must understand packet processing, control systems, and protocols independently; no single conceptual model unifies all three

---

## When This Choice Stops Being Correct

If the portfolio goal shifts to demonstrating a **production SDN system**, not educational comparison, consolidate to single technology (e.g., eBPF + Rust for all layers). This architecture trades off production simplicity for educational depth.

---

## Alternatives Considered

**Single language, single framework (e.g., all Rust)**  
Simplifies the stack and allows sharing patterns, testing harnesses, and deployment models. Rejected because it obscures the engineering tradeoffs that make the portfolio educational — DPDK's lock-free rings vs eBPF's kernel seamlessness, Go's simplicity vs Python's rapid iteration.

**Monolithic application (everything in one binary)**  
Reduces operational complexity and communication latency. Rejected because it defeats the educational goal: viewers cannot see the abstraction boundaries or understand how components interact through defined interfaces (gRPC, REST).

**Microservices with message queue (Kafka/Redis)**  
Decouples components and allows independent scaling. Rejected as over-engineering for a portfolio project; Docker Compose's networking is sufficient.

---

## Related

- [ADR-0002](0002-dpdk-vs-ebpf.md) — Detailed comparison of DPDK and eBPF implementations
- [ADR-0003](0003-grpc-southbound.md) — Southbound gRPC protocol design
- [ADR-0004](0004-go-controller-design.md) — Controller architecture and APIs
- [ADR-0005](0005-bgp-vxlan-evpn.md) — Fabric protocol selection and design
- [ADR-0007](0007-monorepo-structure.md) — Repository organization rationale
