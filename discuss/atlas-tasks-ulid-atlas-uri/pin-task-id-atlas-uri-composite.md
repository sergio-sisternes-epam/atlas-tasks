---
type: decision
title: "Pin — task_id is the full atlas://…/ULID composite"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: accepted
kva: alive
reality: current
description: "Living pin: task_id IS the full atlas://…/ULID composite string (not ULID-only with derived URI, not split fields)."
tags: [atlas-tasks, pin, task-id, atlas-uri, ulid]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Decision

For v0.5-shaped identity, **`task_id` is the full `atlas://…/ULID` composite string**.

Rejected for this pin (recorded so we do not re-open without cause):

- **A)** `task_id` is the ULID only, and `atlas://` is a derived canonical URI.
- **C)** Split fields (separate ULID field and separate atlas URI / home-store field).

## Rationale

Dependencies may target tasks in **other Atlases**. The id itself must carry home-store identity so a pointer can be resolved without an ambient “current Atlas” assumption.

## Alternatives considered

| Option | Shape | Why not (this pin) |
| --- | --- | --- |
| A | ULID-only `task_id` + derived `atlas://` | Home store is not in the id; cross-Atlas targets need extra context. |
| B (chosen) | `task_id` = full `atlas://…/ULID` | Id is self-describing across Atlases. |
| C | Separate fields | Two sources of truth; easier drift; callers must always pass both. |

## Consequences

- Mint still produces a ULID; the stored/passed `task_id` embeds it inside an `atlas://` URI.
- Exact URI grammar is pinned in [Pin — atlas:// physical pointer path](pin-atlas-uri-physical-path.md): `atlas://<atlas_id>/tasks/<ULID>` resolves to the home store's `tasks/<ULID>.md` pointer.
- Cross-Atlas `kind:dependency` / `kind:blocks` **are in-scope**; `parent` / `sub_tasks` stay same-Atlas — see [Pin — parent/sub_tasks same-Atlas; dependency/blocks may cross](pin-cross-atlas-dependency-scope.md).
- Migration off kebab slugs is a **hard cut** (no dual-read) — see [Pin — migrate hard cut](pin-migrate-hard-cut-kebab-to-atlas-uri.md).
- Human-facing display is title + ULID only (no kebab display_slug) — see [Pin — human-facing](pin-human-facing-title-ulid.md).

## Provenance

Pinned by the maintainer during design review on 2026-10-01. The Discuss facilitator and the package steward must not reopen A vs B vs C without the maintainer.
