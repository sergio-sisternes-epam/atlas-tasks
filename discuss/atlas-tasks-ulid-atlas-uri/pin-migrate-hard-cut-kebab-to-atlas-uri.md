---
type: decision
title: "Pin — migrate hard cut: rewrite kebab task_ids to atlas://…/ULID (no dual-read)"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: accepted
kva: alive
reality: current
description: "Living pin: v0.5 migrate rewrites every kebab task_id to atlas://<atlas_id>/tasks/<ULID>; no dual-read of old kebab ids."
tags: [atlas-tasks, pin, migrate, hard-cut, ulid, atlas-uri]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-atlas-uri-physical-path.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-human-facing-title-ulid.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Decision

The v0.5 identity migrate is a **hard cut**:

1. **Rewrite** every stored kebab `task_id` (and every reference that used a kebab as the id) to the canonical form `atlas://<atlas_id>/tasks/<ULID>`.
2. **Mint** a ULID per existing task during migrate; embed it in that URI; rename pointer files to `tasks/<ULID>.md` to match the physical path pin.
3. **No dual-read:** after migrate, the skill must **not** accept, resolve, or shim old kebab ids. Unknown kebab → fail closed (same class of hard cut as v0.3 dropping `todo_id`).

Parent / `sub_tasks` / `kind:dependency` / `kind:blocks` edges that pointed by kebab id are rewritten to the new `atlas://…/ULID` (or to pointer paths that resolve via that id), in the same migrate pass.

## Rationale

Dual-read keeps two identity worlds forever and breaks the “id is self-describing across Atlases” pin. Prior atlas-tasks cuts already preferred hard rewrite over shims.

## Alternatives considered

| Option | Shape | Why not (this pin) |
| --- | --- | --- |
| Dual-read kebab + URI | Accept both during a long window | Permanent ambiguity; cross-Atlas resolve cannot trust kebab. |
| Soft alias map forever | Keep kebab→ULID table | Second source of truth; rename/collision debt. |
| Hard cut (chosen) | One rewrite; kebab ids dead | Clear contract for the package steward cut. |

## Consequences

- Package steward migrate path owns the rewrite; Discuss does not implement the package here.
- Callers and scenarios that still pass kebab `task_id` must be updated in the same cut.
- Human-facing lists use title + ULID; they do not revive kebab as a display slug.

## Provenance

Pinned by the maintainer on 2026-10-01, when Discuss continued after the identity-shape pins.
