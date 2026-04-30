# ADR 0003: gRPC for Southbound Protocol

**Date:** 2026-04-29
**Status:** Accepted

## Context

Controller needs to communicate with fabric devices for state management and config distribution.

## Decision

Use gRPC for southbound protocol (controller to devices). REST API for northbound (external clients).

## Rationale

**gRPC:**
- Efficient binary protocol (vs REST/JSON overhead)
- Streaming support for state notifications
- Type-safe via protobuf
- Connection pooling reduces overhead

**REST (Northbound):**
- Human-friendly for API exploration
- Standard HTTP tooling (curl, browsers)
- Easier for external integrations

## Consequences

- Fabric devices need gRPC client library
- Protobuf schema coupling between controller and devices
- Better performance and lower latency than REST everywhere
- Clearer separation between internal and external APIs
