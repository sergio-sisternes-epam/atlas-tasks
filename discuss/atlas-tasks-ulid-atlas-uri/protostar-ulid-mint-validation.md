---
type: protostar
title: "ULID mint and validation rules for atlas-tasks"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: open
kva: forming
growth: true
star_kind: question
reality: current
description: "Open: timestamp source, monotonic generation, collision handling, and preserve already-minted ID on migration retry — not locked with the identity shape pins."
tags: [atlas-tasks, protostar, ulid, mint, validation]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-migrate-hard-cut-kebab-to-atlas-uri.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Idea

Lock ULID **mint and validation** rules for v0.5-shaped atlas-tasks identity. Identity shape (`task_id` = `atlas://<atlas_id>/tasks/<ULID>`) is already pinned; mint behaviour is not.

## Why it matters

Without explicit mint/validation pins, package implement can invent incompatible clocks, collision handling, or re-mint on migrate retry — breaking idempotent hard-cut migrate and cross-Atlas uniqueness expectations.

## Open cuts (do not decide alone)

1. **Timestamp source** — which clock feeds the ULID timestamp component (wall clock, store-authoritative, agent-local)?
2. **Monotonic generation** — how to guarantee monotonicity under concurrent mints in one Atlas (and whether cross-Atlas monotonicity is required at all).
3. **Collision handling** — detect and retry vs fail closed when a minted ULID already exists as a pointer.
4. **Migration retry preserve-ID** — on hard-cut migrate, if a kebab→`atlas://…/ULID` rewrite is retried, preserve the already-minted ULID for that task (no second mint).

## Next probe

Ask the maintainer (or the package steward once the maintainer unlocks it) which cuts are required before Autogenesis; record a living pin or terminate losing frames.
