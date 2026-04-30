# ADR-0007: Monorepo Structure — Single Repository for Three Layers

**Status**: Accepted  
**Date**: 2026-04-29  
**Deciders**: Portfolio architect

---

## Context

The portfolio has three layers (foundation, controller, fabric), four languages (C, Rust, Go, Python), and needs to be deployable as a single lab environment.

The question is repository structure:

1. **Monorepo** — All three layers in one Git repository with subdirectories per layer (`foundation/`, `controller/`, `fabric/`)
2. **Polyrepo** — One repository per layer; linked via Git submodules or separate clones
3. **Hybrid** — Main monorepo for controller; submodules for foundation/fabric

Each approach has tradeoffs:
- **Monorepo**: Single clone, easy lab setup, atomic commits across layers. Problem: Docker images build all layers even if one changes.
- **Polyrepo**: Independent development cycles, separate CI/CD per layer. Problem: Coordinating versions across repos, manual submodule management.
- **Hybrid**: Compromise. Problem: Complexity of managing mixed repos.

---

## Decision

Adopt **monorepo** with clear layer separation:

```
chakraview-networking-sdn/
├── foundation/
│   ├── dpdk/              # C code, Makefile, tests
│   └── ebpf/              # Rust code, Cargo.toml, tests
├── controller/
│   ├── api/               # Protocol buffer definitions
│   ├── cmd/               # Binaries (sdn-controller)
│   ├── pkg/               # Libraries (topology, discovery)
│   ├── go.mod, go.sum     # Go dependencies
│   └── tests/
├── fabric/
│   ├── bgp/               # BGP speaker module
│   ├── vxlan/             # VXLAN tunnel module
│   ├── evpn/              # EVPN route handler
│   ├── device/            # Simulated device driver
│   ├── requirements.txt    # Python dependencies
│   └── tests/
├── lab/
│   ├── docker-compose.yml # Service definitions
│   ├── scripts/           # init.sh, health checks
│   └── .env.example       # Configuration template
├── docs/                  # Architecture, ADRs, guides
├── Makefile               # Root build orchestration
└── .gitignore
```

**Why monorepo:**
- Single `git clone` gives viewers the entire system
- Atomic commits across layers (e.g., "add EVPN routes + controller support" is one commit)
- Root Makefile orchestrates `make build` across all three layers
- Lab startup is simple: `docker-compose up` in lab/ directory

**Build isolation:**
Each layer has its own build tool (Make for C/Rust, Go modules for Go, pip for Python) and produces independent artifacts (binaries, libraries, images). Monorepo structure does not mean shared build logic.

---

## Consequences

**Positive:**
- **Unified deployment**: One repo = one lab experience. No version coordination headaches.
- **Atomic changes**: A feature that touches controller + fabric is a single commit with clear dependencies
- **Single issue tracker**: All bugs, features, docs in one GitHub repo (not 3)
- **Root-level orchestration**: Makefile at repo root coordinates build, test, clean across all layers
- **Easy for learners**: Clone once, explore three layers in situ

**Negative:**
- **Mixed languages**: CI/CD pipelines must handle C, Rust, Go, Python; testing is more complex
- **Versioning**: No independent versioning per layer; all release together (e.g., v1.0.0 = all layers at v1.0.0)
- **Build bloat**: Docker image builds are larger; changing one line of Python rebuilds the C binary container even though it didn't change
- **Merge conflicts**: Easier for three layers to edit the same root Makefile; coordination required

---

## Constraints

- Each layer is independently buildable: `cd controller && go build ./cmd/sdn-controller` must work in isolation
- Dependencies are explicitly declared per layer (go.mod, Cargo.toml, requirements.txt); no shared dependency file
- Root Makefile calls sub-Makefiles in each directory; does not duplicate build logic

---

## When This Choice Stops Being Correct

If the three layers are developed by different teams with independent release cycles, switch to polyrepo. Example: "DPDK agents released quarterly, controller monthly, fabric protocols weekly."

If individual layers are extracted for use in other projects (e.g., the Go controller used in a different SDN), polyrepo becomes appropriate.

---

## Alternatives Considered

**Polyrepo with Git submodules**  
Independent repos with clear API boundaries. Rejected because submodules introduce version coordination complexity; viewers cloning the main repo still see "submodule not initialized" errors on first checkout.

**Polyrepo with copy-paste**  
Layers in separate repos; docs contain copy-paste instructions. Rejected as unmaintainable; any change requires updating across repos manually.

**Monorepo with monolithic Makefile**  
Single Makefile with all layer logic. Rejected because future developers cannot build layers in isolation; understanding layer dependencies becomes harder.

---

## Related

- [ADR-0001](0001-architecture.md) — Three layers that are unified in this monorepo
- [Data Engineering Patterns ADR-0001](../../chakraview-data-engineering-patterns/docs/adrs/ADR-0001-pattern-matrix-structure.md) — Similar structure decision for another portfolio project
- `/Makefile` — Root orchestration
- `/docs/` — Architecture and ADRs for the whole project
