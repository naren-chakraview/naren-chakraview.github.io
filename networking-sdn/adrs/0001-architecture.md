# ADR 0001: Three-Layer SDN Architecture

**Date:** 2026-04-29
**Status:** Accepted

## Context

We need to build a portfolio project demonstrating modern SDN concepts with hands-on labs.

## Decision

Adopt a three-layer architecture:
- **Foundation Layer:** High-performance packet processing (DPDK vs eBPF)
- **Control Plane:** Intent-based SDN controller (Go)
- **Fabric Protocols:** Routing/overlay implementations (Python)

## Rationale

1. **Foundation:** DPDK shows user-space performance; eBPF shows kernel efficiency. Comparison is educational.
2. **Control:** Go enables fast gRPC + REST API implementation.
3. **Fabric:** Python allows rapid prototyping of BGP, VXLAN, EVPN.
4. **Integration:** Docker Compose lab lets users declare intent and observe execution.

## Consequences

- Three distinct tech stacks require different tooling/expertise
- Docker Compose overhead is acceptable for lab demonstration
- Performance is not production-grade but sufficient for portfolio/learning
