# ADR-0003: Southbound Protocol — gRPC

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

The SDN controller must communicate with distributed fabric devices (DPDK agents, eBPF agents, simulated switches/routers) across three critical channels:

1. **Device discovery** — controller learns of device existence and capabilities
2. **State synchronization** — controller instructs devices: "install this route," "create this tunnel"
3. **Statistics streaming** — devices report packet counts, error conditions, memory usage

The protocol must be:
- **Type-safe**: Schema mismatch between controller and device should be caught at compile time, not at runtime
- **Efficient**: Northbound REST APIs hit performance limits under high-throughput device updates; southbound cannot afford JSON serialization overhead
- **Bidirectional**: Controller pushes config; devices push state updates asynchronously
- **Language-agnostic**: Controller is Go; devices are C (DPDK), Rust (eBPF), Python (simulated); protocol must work across all

---

## Decision

Adopt **gRPC for southbound protocol** (controller ↔ devices) and **REST for northbound** (external clients ↔ controller).

**Southbound (gRPC):**
- Proto definition: `fabric.proto` with FabricAgent service
- RPC methods: `RegisterAgent`, `SetRoutes`, `SetTunnels`, `GetStats`
- Streaming: Server-side streaming for continuous stats updates
- TLS: Mutual authentication required (certificates distributed in lab setup)

**Northbound (REST):**
- HTTP API served on `:8080`
- Endpoints: `/api/v1/topology`, `/api/v1/health`, `/api/v1/routes`, `/api/v1/tunnels`
- JSON responses for easy curl/browser exploration
- OpenAPI spec generated from code

The distinction is clear: **gRPC is for machine-to-machine high-performance communication**; **REST is for human operators and external tools**.

---

## Consequences

**Positive:**
- **Type safety**: Protobuf compiler enforces schema compatibility across languages; no runtime JSON parsing errors
- **Performance**: Binary format (gRPC/protobuf) reduces bandwidth 5-10x vs JSON over HTTP/1.1; connection pooling reduces handshake overhead
- **Streaming**: Server-side streaming allows devices to push stats continuously without polling, reducing control plane latency
- **Code generation**: protoc generates device client stubs in Go, Rust, Python automatically from one `.proto` file
- **Educational value**: Learners see the difference between high-performance internal APIs (gRPC) and user-facing APIs (REST)

**Negative:**
- **Debugging complexity**: gRPC is opaque; HTTP/REST is human-readable. Lab must provide debugging tooling (`grpcurl`) to inspect messages
- **Protobuf coupling**: Any protocol change (add field, rename RPC) requires regenerating code in all languages and coordinating deployments
- **Client library burden**: Each device type (C, Rust, Python) needs gRPC client library setup; testing becomes more complex

---

## Constraints

- Southbound gRPC runs on port `:50051` in lab; TLS certificates are self-signed (acceptable for portfolio)
- REST endpoints are HTTP-only (no TLS) within Docker Compose; TLS would require additional cert infrastructure
- Protobuf v3 syntax: no required fields (forward/backward compat), no field presence (all optionals)

---

## When This Choice Stops Being Correct

If the portfolio grows to support 100+ heterogeneous device types (not just DPDK/eBPF/simulated), message schema coupling becomes painful. At that scale, consider versioning strategy (gRPC service versioning) or message envelope pattern (protobuf `Any` wrapper with version field).

---

## Alternatives Considered

**REST for both northbound and southbound**  
Simpler, fully HTTP-based, easier debugging. Rejected because JSON serialization overhead would be visible in performance comparisons; benchmark between DPDK/eBPF would be muddied by protocol overhead.

**AMQP/RabbitMQ message queue**  
Decouples controller from devices; devices can buffer config changes. Rejected as over-engineering for a lab environment; direct RPC calls are appropriate for portfolio scope.

**Protobufs over HTTP/2 without gRPC framework**  
Binary format, manual connection management. Rejected because gRPC handles connection pooling, flow control, and deadline propagation automatically.

---

## Related

- [ADR-0001](0001-architecture.md) — Three-layer architecture; controller sits at the boundary
- [ADR-0004](0004-go-controller-design.md) — Controller implementation details
- `/controller/api/fabric.proto` — Actual service definition
