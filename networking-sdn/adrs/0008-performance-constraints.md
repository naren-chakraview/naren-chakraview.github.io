# ADR-0008: Performance and Scalability — Educational Over Production

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

A portfolio project will be benchmarked: viewers will run the lab, measure throughput, latency, CPU, and memory, and compare against claims in documentation.

The question is: **what are we optimizing for?**

1. **Production-like performance**: DPDK reaches 10M pps; real BGP speakers handle 100K routes. We could chase these numbers.
2. **Educational clarity**: Trade performance for readability. Code optimized for performance is often harder to understand.

These are in tension. A production-optimized DPDK app uses NUMA awareness, multicore scaling, CPU pinning, and lock-free data structures — all of which obscure the core packet processing logic. A production-optimized BGP speaker has route dampening, memory pooling, and lock-free message queues.

The portfolio cannot be both: we choose one. If we optimize for production, viewers get impressive numbers but opaque code. If we optimize for education, viewers understand the system but see mediocre performance and assumptions of limitations.

---

## Decision

**Optimize for education, not production performance.** Set explicit performance constraints that are "good enough" for a lab and document them clearly:

| Component | Constraint | Rationale |
|-----------|-----------|---|
| **DPDK** | 100K pps max; single-threaded polling | Shows packet processing fundamentals without multicore complexity |
| **eBPF** | 1M pps with XDP; no TC hooks | Demonstrates kernel fast path without filtering complexity |
| **Controller** | 100 devices max; 1K routes per device | In-memory topology is sufficient for lab |
| **BGP** | 100K routes total; 10 peers max per device | Educational FSM without route dampening |
| **VXLAN** | 100 tunnels per device | Sufficient for multi-device lab topology |
| **Lab startup** | 30 seconds from `docker-compose up` to all health checks passing | Acceptable for interactive use |

Each constraint is documented in the code as a comment. When a viewer hits the limit (e.g., tries to configure 200 tunnels), the system fails explicitly with an error message that cites the ADR.

---

## Consequences

**Positive:**
- **Code clarity**: No NUMA optimizations, no lock-free rings, no CPU pinning. Code is straightforward.
- **Testing simplicity**: Small limits mean test fixtures are small; validation is easier
- **Faster iteration**: Developers can understand and modify the code without grokking production complexity
- **Honest documentation**: Constraints are explicit; viewers know what they're seeing is educational, not production

**Negative:**
- **Modest numbers**: DPDK at 100K pps is 100x slower than production. Viewers might think "this can't be real SDN."
- **Scaling not tested**: The code has not been validated at production scale; scaling behavior is unknown
- **Benchmark apples-to-apples impossible**: Cannot compare against production controllers directly

---

## Assumptions and Trade-offs

**We accept that:**
- Latency variance is high due to Docker Compose and Python; no real-time guarantees
- Memory usage is not optimized; no pooling or pre-allocation
- CPU contention is possible; services run in shared containers without isolation

**We optimized for:**
- Code readability (no micro-optimizations)
- Fast iteration (build times under 2 minutes)
- Understandability (clear interfaces, explicit error messages)

---

## Extension Points

Code includes marked extension points for future optimization without breaking educational value:

```python
# EXTENSION: Replace with lock-free queue for multicore BGP peer handling
bgp_peers = {}  # Currently dict, could be concurrent.futures pool
```

A learner can tackle one optimization in isolation (e.g., "implement multicore BGP peer handling") without refactoring the entire codebase.

---

## When This Choice Stops Being Correct

If the portfolio goal shifts to production SDN or competitive benchmarking, revisit all optimization decisions. Single-threaded code must become multicore; in-memory state must become persistent; educational simplifications must be removed.

---

## Alternatives Considered

**Production-grade optimization**  
DPDK with multicore, eBPF with TC, controller with persistent state, BGP with dampening. Rejected because the resulting code is 3-5x larger and requires understanding of systems concepts (memory ordering, lock-free algorithms, kernel internals) that obscure the main ideas.

**Hybrid: optimize hot path only**  
Keep most code simple, but optimize DPDK and eBPF since they're on the data plane. Rejected because inconsistent optimization creates the worst of both worlds: some code is hard to understand, but performance is still not production-grade.

**Benchmark against production**  
Measure against production OVS, VPP, or Snabb. Rejected because it sets the wrong expectations; viewers would see we are 100x slower and conclude the design is flawed, when the real issue is optimization choices, not architecture.

---

## Monitoring and Observability

Despite performance constraints, the system includes observability hooks:
- Prometheus metrics exposed at `/metrics` for CPU, memory, packet counts per device
- Structured logging with timestamps for tracing request flow
- gRPC reflection enabled for debugging with `grpcurl`

This allows learners to **understand the system's behavior** even if raw throughput is modest.

---

## Related

- [ADR-0001](0001-architecture.md) — Overall three-layer architecture that accepts these constraints
- [ADR-0002](0002-dpdk-vs-ebpf.md) — DPDK and eBPF constraints documented separately
- Code comments marking EXTENSION points throughout the codebase
