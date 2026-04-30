# ADR-0005: Fabric Protocols — BGP, VXLAN, and EVPN

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

The fabric layer implements the protocols that network devices use to communicate with each other: exchanging routing information, establishing tunnels, and reaching consensus on service placement.

Three complementary protocols form the modern datacenter fabric:

1. **BGP (Border Gateway Protocol)** — Routing protocol; devices exchange IP reachability information via TCP sessions
2. **VXLAN (Virtual Extensible LAN)** — Overlay tunneling; encapsulates Layer 2 frames in UDP packets to create virtual networks
3. **EVPN (Ethernet VPN)** — Addresses the gap between BGP (IP-only) and VXLAN (Layer 2); carries MAC/IP bindings over BGP to enable virtual bridging at scale

Production datacenters (AWS, Google, Azure) combine these: BGP distributes reachability; VXLAN creates tunnels; EVPN ensures MAC/IP consistency across the fabric.

The portfolio must demonstrate all three to show a complete fabric. But each is complex: BGP has a 13-state FSM, VXLAN has tunnel state, EVPN has multiple route types. The question is depth vs breadth.

---

## Decision

Implement all three protocols in Python with **deliberate simplifications** that keep the code teachable:

| Protocol | Scope | Simplification |
|----------|-------|---|
| **BGP** | FSM, peer management, route advertisement | Single ASN (no ASN path prepending); no route dampening or MED |
| **VXLAN** | Tunnel establishment, encapsulation | Static VNI assignments; no VXLAN Group Policy extension |
| **EVPN** | Type 2 (MAC/IP) and Type 5 (IP prefix) routes | No Type 1/3/4 (EAD/Inclusive mcast/Ethernet AD) |

Each protocol is its own module (`bgp/`, `vxlan/`, `evpn/`) with a well-defined interface. Simulated devices compose these modules.

**Composition pattern:**
- Device has a BGP speaker (manages peer sessions, exchanges routes)
- Device has VXLAN tunnels (maintains encapsulation state)
- Device has EVPN route handler (interprets EVPN routes from BGP and installs tunnels)

---

## Consequences

**Positive:**
- **Educational completeness**: Learners see the three essential fabric technologies in one lab
- **Real-world relevance**: Exact protocols used in production datacenters
- **Protocol interaction**: Learners understand how BGP (routing) + VXLAN (tunneling) + EVPN (binding) work together
- **Extensible**: Marked extension points in code for adding MED, dampening, Type 4 routes, etc.

**Negative:**
- **Implementation complexity**: 13-state BGP FSM, tunnel state management, EVPN route parsing require careful coding
- **Testing difficulty**: Inter-device protocol synchronization is hard to test; requires multi-device topology
- **Not production-complete**: Simplifications (single ASN, static VNI, no dampening) mean code is educational but not a real speaker
- **Performance irrelevant**: Python gRPC client/server is slow; protocol overhead will dominate, not the protocol logic

---

## Constraints

- BGP speaker listens on TCP `:179` per simulated device
- VXLAN tunnels are point-to-point (one tunnel = one encapsulation rule); no multicast replication
- EVPN Type 2 routes carry MAC+IP; Type 5 carry IP prefix. Both are handled by the same EVPN module
- Device registration with controller is manual (device calls gRPC `RegisterAgent`); no automatic discovery

---

## When This Choice Stops Being Correct

If the portfolio goal becomes production SDN, use established libraries: `GoBGP` (Go), `FRRouting` (C), `Scapygrpc` (Python). Don't reimplement BGP/EVPN.

---

## Alternatives Considered

**Simplified unicast only (no BGP/EVPN, just static routes)**  
Easier to understand and test. Rejected because it omits the distributed consensus problem that makes fabric protocols interesting; learners wouldn't see how devices agree on topology.

**GoBGP library + Python wrapper**  
Production BGP implementation. Rejected because students wouldn't understand BGP internals; GoBGP is a black box.

**OSPF instead of BGP**  
OSPF has simpler state machine (fewer states). Rejected because BGP is more common in modern datacenters and more interesting educationally (TCP-based, external routing protocol).

---

## Related

- [ADR-0001](0001-architecture.md) — Fabric is the third layer of three-layer architecture
- [ADR-0004](0004-go-controller-design.md) — Controller manages fabric devices
- `/fabric/bgp/fsm.py` — BGP finite state machine implementation
- `/fabric/vxlan/tunnel.py` — VXLAN tunnel management
- `/fabric/evpn/routes.py` — EVPN route types and handling
