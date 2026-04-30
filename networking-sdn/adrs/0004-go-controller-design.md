# ADR-0004: Controller Architecture — Topology, Discovery, and Intent

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

The SDN controller is the "brain" of the system: it accepts intent from operators (routes, tunnels, device groups), discovers the physical network topology, and translates intent into device-level configurations pushed via gRPC.

The controller must manage three responsibilities:

1. **Topology** — Track devices, links, and capabilities; compute shortest paths
2. **Discovery** — Detect when devices register/deregister; handle device failures
3. **Intent** — Accept configuration from REST API; translate to gRPC calls to devices

Naively implemented, these responsibilities become entangled: changes to device state cascade into path computation, which cascades into route installation, leading to race conditions and hard-to-debug ordering issues.

---

## Decision

Separate the controller into three layers, each with one responsibility:

| Layer | Component | Responsibility |
|-------|-----------|---|
| **Topology** | Graph + BFS | Track devices and links; compute paths |
| **Discovery** | Registry | Detect device registration/deregistration; manage device lifecycle |
| **Intent** | REST API | Accept operator intent; validate and translate to RPC calls |

Each layer is independently testable and updates are coordinated through events: discovery detects a device → emits `DeviceRegistered` event → topology consumes it and recomputes paths → intent layer can now push routes to that device.

**Key design pattern: Immutable Graph Snapshots**

The topology graph is immutable within a request: take a snapshot, compute paths, then apply changes atomically. This prevents race conditions where a device disappears during path computation.

---

## Consequences

**Positive:**
- **Separation of concerns**: Topology computation is independent of discovery or intent; can be tested in isolation
- **Event-driven**: Loose coupling between layers via event stream; discovery doesn't need to know about topology or intent
- **Testability**: Graph layer can be tested with fixtures; discovery layer can be tested with mock device registrations
- **Scalability**: Each layer can scale independently; for example, topology can cache paths while discovery handles frequent device churn
- **Educational clarity**: Students can understand each layer independently before understanding the interaction

**Negative:**
- **Event ordering complexity**: Must ensure discovery events are processed before intent is applied; event queue adds latency
- **Snapshot consistency**: Multiple snapshots exist simultaneously; must ensure they are synchronized
- **Debugging difficulty**: Intent request that fails requires understanding topology at the time, which may have changed

---

## Constraints

- Topology graph is memory-resident: suitable for <10K devices. For larger networks, consider persistent store (etcd, Consul)
- Discovery is gRPC-based: devices must call `RegisterAgent` RPC; no automatic discovery (LLDP/CDP-style learning omitted for simplicity)
- Intent API is REST-only: no northbound gRPC (keep the REST/gRPC boundary clear)

---

## When This Choice Stops Being Correct

If the network grows beyond 1K devices or devices churn more than 10 times/second, the immutable snapshot approach becomes expensive (copies entire graph). At that scale, use event sourcing: store a log of topology changes and reconstruct state on demand.

---

## Alternatives Considered

**Monolithic controller**  
All logic in one component; simpler to reason about initially. Rejected because topology, discovery, and intent changes would race; debugging would require understanding the entire controller.

**Microservices: separate controller services**  
Each service (Topology, Discovery, Intent) runs independently; communicate via message queue. Rejected as over-engineering for portfolio scope; Docker Compose communication is sufficient.

**Graph database (Neo4j, DGraph)**  
Query topology via graph queries rather than custom BFS. Rejected because it adds operational complexity; in-memory graph is sufficient for portfolio.

---

## Related

- [ADR-0001](0001-architecture.md) — Controller sits in the control plane
- [ADR-0003](0003-grpc-southbound.md) — gRPC interface controller exposes to devices
- `/controller/pkg/topology/` — Implementation details (graph.go, discovery.go, topology.go)
