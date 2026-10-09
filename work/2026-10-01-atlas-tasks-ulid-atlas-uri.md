---
type: work
title: "atlas-tasks task_id as ULID + atlas:// tracing"
created: 2026-10-01
work_id: 2026-10-01-atlas-tasks-ulid-atlas-uri
status: open
description: "Discuss orbit to lock a v0.5-shaped task identity: atlas:// id shape, migrate off kebab slugs, and same-Atlas vs cross-Atlas scope. ULID mint/validation remains an open protostar. No Autogenesis until the maintainer unlocks it."
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: related
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: follows
---

## Scope

Lock a v0.5-shaped identity so tasks can traverse Atlases: `atlas://` id shape, migrate off kebab slugs, and what stays same-Atlas-only versus cross-Atlas. ULID mint/validation is a separate open protostar. Package cut is owned by the package steward after Discuss locks; Autogenesis/implement is deferred until the maintainer unlocks it.

## Status

`open` — Discuss identity-shape lock + constellation recorded 2026-10-01; ULID mint/validation protostar still open. Awaiting the maintainer’s unlock before Autogenesis; package steward owns v0.5 package cut.

## Outcomes

Grammar, display, migrate, and cross-Atlas scope pins locked; constellation join filed. Open protostar remains for ULID mint/validation (timestamp, monotonicity, collision, migrate-retry preserve-ID). No product / package writes in this orbit.
