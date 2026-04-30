# Networking Systems Landscape — How This Portfolio Relates

This guide positions the networking-sdn portfolio within the broader landscape of SDN, networking, and packet processing systems.

## Packet Processing Landscape

### Foundation Layer Comparison

| System | Approach | Language | Use Case | Vs. This Portfolio |
|--------|----------|----------|----------|---|
| **DPDK** | Userspace polling, direct NIC access | C | Telco, high-performance routing | This portfolio uses DPDK for comparison; production uses DPDK in VPP, ODP, f-stack |
| **eBPF/XDP** | Kernel VM, NIC driver hook | C with libbpf | Cloud-native, filtering, observability | This portfolio explores eBPF; industry moves toward eBPF (Cilium, Calico, Suricata) |
| **OVS (Open vSwitch)** | Kernel module + userspace | C | Virtual switching, OpenStack | Educational; OVS is a complete switch (this portfolio is modular comparison) |
| **VPP (Vector Packet Processing)** | Userspace graph of processing nodes | C | NFV (Network Function Virtualization) | Production-grade DPDK alternative; higher complexity |
| **Snabb** | Userspace Lua + C | Lua/C | Streaming, carrier-grade | Simpler than VPP; higher-level language; less common than DPDK |

**Positioning:**
- This portfolio demonstrates DPDK and eBPF side-by-side (unique)
- Shows educational implementations, not production-optimized
- Suitable for learning fundamentals before studying VPP or Snabb

## SDN Controller Landscape

### Control Plane Comparison

| System | Architecture | Language | Scale | Vs. This Portfolio |
|--------|--------------|----------|-------|---|
| **OpenDaylight** | Microservices, modular plugins | Java/Python | Enterprise datacenter | Industrial-strength; this portfolio is simpler, focused on core concepts |
| **ONOS** | Clustered control plane | Java | Large-scale ISP/datacenter | Production SDN controller; this portfolio is single-instance educational |
| **OpenFlow Controllers** (Ryu, Floodlight) | Application framework | Python/Java | Medium networks | Ryu similar to this portfolio in simplicity; this portfolio uses gRPC instead of OpenFlow |
| **Cisco ACI** | Intent-based networking | Proprietary | Large enterprise | Production system; this portfolio is open-source reference |
| **Kubernetes IPAM Controllers** (Calico, Weave, Cilium) | Distributed control loop | Go/Rust | Container orchestration | Modern cloud-native SDN; this portfolio predates K8s understanding |

**Positioning:**
- This portfolio is an **educational SDN controller**, not production
- Simpler than OpenDaylight/ONOS (no clustering, no persistence)
- Similar in scope to simple OpenFlow controllers (Ryu), but uses gRPC instead of OpenFlow
- Modern approach (gRPC + topology-driven) vs. legacy (OpenFlow + flow tables)

## Fabric Protocol Landscape

### Routing and Overlay Comparison

| Protocol/System | Function | Scale | Vs. This Portfolio |
|---------|----------|-------|---|
| **BGP** (Border Gateway Protocol) | Path-vector routing | Internet scale (100K+ peers) | Industry standard; this portfolio implements simplified FSM |
| **OSPF** (Open Shortest Path First) | Link-state routing | Enterprise LAN scale | Simpler than BGP (fewer states); not implemented (BGP chosen for modern relevance) |
| **ISIS** | Link-state routing | ISP backbone | Similar to OSPF; this portfolio omits for scope |
| **VXLAN** | Virtual overlay tunneling | Datacenter | Industry standard; this portfolio implements core logic |
| **Geneve** | Generalized encapsulation | Emerging replacement | Flexible; more complex than VXLAN; omitted from portfolio |
| **EVPN** (Ethernet VPN) | Distributed virtual networking | Modern datacenter | Industry convergence point; this portfolio implements Type 2 & 5 |
| **SD-WAN** (Cisco Viptela, etc.) | Intent-based WAN routing | Branch networks | Not in portfolio; builds on same concepts (intent → deployment) |

**Positioning:**
- This portfolio teaches **datacenter fabric protocols** (BGP/VXLAN/EVPN)
- Not WAN routing (no OSPF/ISIS) or pure L2 bridging (no STP)
- Real-world relevant: major cloud providers use exactly this combination

## Lab and Deployment Landscape

### Orchestration Comparison

| Tool | Scope | Use Case | Vs. This Portfolio |
|------|-------|----------|---|
| **Docker Compose** | Single-host containers | Development, education | This portfolio uses Compose; simplicity is advantage |
| **Kubernetes** | Multi-host orchestration | Production container platforms | Could migrate this portfolio to K8s; Compose is sufficient for learning |
| **Vagrant + Virtualbox** | Virtual machines on host | Testing, demos | More overhead than containers; portfolio uses Compose instead |
| **Terraform + Cloud** (AWS, GCP) | Infrastructure-as-code | Cloud deployment | Production-grade; portfolio is self-contained (no cloud dependency) |

**Positioning:**
- Docker Compose is **appropriate for portfolio scope**
- K8s would add unnecessary complexity (no multi-node coordination needed)
- Enables viewers to run on laptop (Docker Desktop) without cloud account

## Educational Positioning

### Compared to Existing Courses/Textbooks

| Resource | Focus | Depth | Vs. This Portfolio |
|----------|-------|-------|---|
| **Kurose-Ross Textbook** | Networking fundamentals, layer model | Breadth (all layers) | Portfolio goes deep on L2/L3; textbook breadth |
| **BGP Design and Implementation** (Evans) | BGP protocol mastery | Very deep (1000+ pages) | Portfolio simplified FSM; book is authoritative |
| **Data Center Networks** (Singla et al., CMU course) | Datacenter architecture | Moderate | Portfolio shows fabric layer; course broader architecture |
| **ONF SDN Course** (Open Networking Foundation) | OpenFlow-based SDN | Educational implementation | Portfolio is gRPC-based (more modern); course is OpenFlow (more standardized) |
| **Linux Kernel Networking** (Salim's guides) | Kernel networking internals | Very deep | Portfolio's eBPF layer is surface compared to kernel deep-dive |

**Positioning:**
- This portfolio is a **hands-on complement** to textbooks and courses
- Implements concepts from Kurose-Ross, Evans, and ONF courses
- More modern than OpenFlow courses (gRPC instead of OpenFlow)
- Simpler than kernel networking deep-dive but shows modern kernel extensibility

## Skill Progression Map

This portfolio is designed as a stepping stone:

```
Foundation (Kurose-Ross)
    ↓
Packet Processing Concepts (this portfolio: DPDK/eBPF)
    ↓
Routing Protocols (this portfolio: BGP)
    ↓
Network Virtualization (this portfolio: VXLAN/EVPN)
    ↓
SDN Architecture (this portfolio: 3-layer controller)
    ↓
Production Systems (OpenDaylight, ONOS, Kubernetes CNI)
```

After understanding this portfolio, learners can:
- Read VPP source code (advanced packet processing)
- Deploy Cilium on Kubernetes (production eBPF CNI)
- Understand Juniper/Cisco fabric implementations (similar to fabric layer)
- Study OpenDaylight or ONOS (production SDN control planes)

## Technology Trends

### What This Portfolio Shows That's Current (2026)

1. **eBPF as first-class citizen** — Not legacy, but alongside userspace
2. **gRPC for inter-component communication** — REST reserved for humans
3. **Containers as deployment unit** — Not VMs or bare metal
4. **Distributed protocols in modern languages** — Go for control, Python for simplicity

### What's Emerging (not in this portfolio)

1. **AI/ML for network optimization** — Predicting failures, traffic engineering via learning
2. **Kubernetes integration** — In-kernel CNI (Cilium), multi-cluster routing
3. **Observability-first** — eBPF-based observability (Tetragon, Pixie)
4. **Intent-based Everything** — Higher-level abstraction over gRPC APIs

## Paths Beyond This Portfolio

### To Go Deeper in Packet Processing

- Study VPP (open source, production DPDK-based switch)
- Learn kernel networking (Linux Kernel Networking, Ulrich Drepper)
- Explore Cilium + Tetragon (eBPF + observability)

### To Go Deeper in SDN

- Deploy OpenDaylight or ONOS (production controllers)
- Study OpenFlow specification (legacy but still relevant)
- Implement new SDN use case (QoS, service chaining, etc.)

### To Go Deeper in Fabric Protocols

- Implement OSPF (link-state alternative to BGP)
- Add route dampening to BGP (real-world complexity)
- Implement EVPN Type 3/4 (multicast, leaf discovery)

### To Combine Multiple Areas

- Deploy production BGP on Linux (FRRouting)
- Build Kubernetes CNI from scratch (similar to Cilium)
- Implement network telemetry with eBPF (Cilium/Tetragon pattern)

## Reference Architecture — Real Systems

This portfolio's three-layer architecture maps to real deployments:

```
Production Deployment:         This Portfolio:
┌────────────────────┐        ┌────────────────────┐
│ Fabric Protocols   │        │ Fabric (BGP/VXLAN/ │
│ (BGP/EVPN/VXLAN)   │        │  EVPN simulated)   │
└────────────────────┘        └────────────────────┘
         ↓                            ↓
┌────────────────────┐        ┌────────────────────┐
│ SDN Controller     │        │ Go Controller with │
│ (Cisco ACI,        │        │ gRPC southbound    │
│ OpenDaylight, etc) │        │ and REST API       │
└────────────────────┘        └────────────────────┘
         ↓                            ↓
┌────────────────────┐        ┌────────────────────┐
│ Packet Processing  │        │ DPDK + eBPF agents │
│ (VPP, OVS,         │        │ (educational)      │
│ Hardware ASICs)    │        │                    │
└────────────────────┘        └────────────────────┘
```

The portfolio is not production (no ASIC, no clustering), but architecturally sound.

## Next Steps

- Choose an area to deepen: [Packet Processing](foundation-layer.md), [Control Plane](controller-layer.md), [Fabric Protocols](fabric-layer.md)
- Compare this to a production system: read Cisco ACI or OpenDaylight documentation
- Extend the portfolio: see [Extending](../extending/) guides
