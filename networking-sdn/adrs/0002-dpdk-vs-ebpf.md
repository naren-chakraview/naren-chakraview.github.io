# ADR 0002: Comparative Study - DPDK vs eBPF

**Date:** 2026-04-29
**Status:** Accepted

## Context

Both DPDK and eBPF offer high-performance packet processing but with different tradeoffs.

## Decision

Implement both DPDK (user-space) and eBPF (kernel-space) forwarding engines in the foundation layer.

## DPDK Advantages

- Direct hardware control via PMDs
- Full packet customization
- Suitable for complex forwarding logic
- Production-proven in real networks

## eBPF Advantages

- Kernel integration (no userspace copies)
- Safer sandbox model
- Ideal for simple, high-throughput scenarios
- Emerging as standard in cloud networking

## Rationale

Teaching both approaches gives learners understanding of the spectrum:
- When to choose each technology
- Integration patterns in heterogeneous setups
- Performance characteristics in different scales

## Consequences

- Lab users can swap implementations at runtime
- Requires maintainability of two stacks
- Excellent for comparative benchmarking
