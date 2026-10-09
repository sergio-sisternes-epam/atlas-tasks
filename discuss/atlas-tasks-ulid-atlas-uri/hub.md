---
type: experience
title: "Hub — atlas-tasks task_id as ULID + atlas:// tracing"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: in-discussion
kva: alive
reality: current
description: "discussion_root. Lock a v0.5-shaped identity so tasks can traverse Atlases: atlas:// shape, migrate off kebab slugs, same-Atlas vs cross-Atlas; ULID mint/validation and cross-Atlas reverse-edge dual-write remain open."
tags: [atlas-tasks, discuss, ulid, atlas-uri, task-id, v0.5]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-atlas-uri-physical-path.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-human-facing-title-ulid.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-migrate-hard-cut-kebab-to-atlas-uri.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-cross-atlas-dependency-scope.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-ulid-mint-validation.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-cross-atlas-reverse-edge.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/constellation-2026-10-01-ulid-atlas-uri.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
---

## Context

Subject: atlas-tasks task_id as ULID + atlas:// tracing.

Objective: Lock a v0.5-shaped identity so tasks can traverse Atlases: atlas:// id shape, migrate off kebab slugs, and what stays same-Atlas-only versus cross-Atlas. ULID mint/validation and cross-Atlas reverse-edge dual-write stay open protostars — not claimed complete with the identity-shape lock.

This page is `discussion_root`. It does not move. The Discuss facilitator runs Discuss on this package Atlas; the package steward owns the v0.5 package cut after lock. No Autogenesis or implement until the maintainer unlocks it.

## What happened

The maintainer and the Discuss facilitator agreed this orbit belongs on `github.com/sergio-sisternes-epam/atlas-tasks` (shared `atlas` branch). Opening seed from design review:

- **v0.4 current reality:** kebab `task_id`; parent and dependency use same-Atlas pointer paths only; cross-Atlas is a non-goal.
- **Ask:** ULID for uniqueness plus `atlas://` for home-store tracing, so tasks can traverse Atlases.
- **Authority:** Discuss here; package steward cuts v0.5 after lock; no Autogenesis until the maintainer unlocks it.
- **First live branch (A/B/C):** parked as a choice, then the maintainer pinned **B** during design review — `task_id` **is** the full `atlas://…/ULID` composite (not ULID-only with a derived URI, not split fields). Reason: dependencies may target tasks in other Atlases, so the id itself must carry home-store identity.

## Outcome

Identity embedding, physical path-form grammar, human-facing title+ULID (no kebab display_slug), hard-cut kebab→URI migrate, and cross-Atlas scope (hierarchy same-Atlas; dependency/blocks may cross, fail-closed resolve) are pinned. Two open protostars remain: [ULID mint and validation](protostar-ulid-mint-validation.md) and [cross-Atlas reverse-edge / dual-write](protostar-cross-atlas-reverse-edge.md). Package implement stays deferred until the maintainer unlocks Autogenesis.

## Related

- [Current reality](current-reality.md) — living thesis
- [Pin — task_id is atlas://…/ULID composite](pin-task-id-atlas-uri-composite.md)
- [Pin — atlas:// physical pointer path](pin-atlas-uri-physical-path.md)
- [Pin — human-facing title + ULID only](pin-human-facing-title-ulid.md)
- [Pin — migrate hard cut kebab → atlas://…/ULID](pin-migrate-hard-cut-kebab-to-atlas-uri.md)
- [Pin — parent/sub_tasks same-Atlas; dependency/blocks may cross](pin-cross-atlas-dependency-scope.md)
- [Protostar — ULID mint and validation (open)](protostar-ulid-mint-validation.md)
- [Protostar — cross-Atlas reverse-edge / dual-write (open)](protostar-cross-atlas-reverse-edge.md)
- [Constellation — 2026-10-01 identity lock](constellation-2026-10-01-ulid-atlas-uri.md)
- [Work stub](../../work/2026-10-01-atlas-tasks-ulid-atlas-uri.md)
