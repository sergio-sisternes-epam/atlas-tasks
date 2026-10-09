---
type: decision
title: "Pin — human-facing display is title + ULID only (no kebab display_slug)"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: accepted
kva: alive
reality: current
description: "Living pin: humans see title plus ULID; no kebab display_slug. Canonical task_id remains atlas://<atlas_id>/tasks/<ULID>."
tags: [atlas-tasks, pin, ulid, display, task-id]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-atlas-uri-physical-path.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Decision

**Human-facing** presentation of a task is **`title` + ULID only**.

- Do **not** mint, store, or display a kebab `display_slug` (or any other slug derived from the title) as a secondary human id.
- The canonical machine `task_id` remains the full composite URI:

```text
atlas://<atlas_id>/tasks/<ULID>
```

- Agents and UIs that need a short human label show the task **title** and the embedded **ULID** (the final path segment). They may show the full `atlas://` URI when tracing or debugging, but must not invent a kebab stand-in for the id.

## Rationale

Kebab slugs collide across Atlases, invite rename churn, and duplicate identity next to the ULID. Title carries meaning for humans; ULID carries uniqueness; `atlas://…/ULID` carries home-store resolve. A third slug adds drift without resolve value.

## Alternatives considered

| Option | Shape | Why not (this pin) |
| --- | --- | --- |
| Keep kebab `display_slug` alongside ULID | Dual human ids | Drift, rename fights, false uniqueness. |
| Title only | No stable short token | Hard to cite in chat/logs without the ULID. |
| Full URI only in every UI | Always show `atlas://…` | Noisy for day-to-day lists; still allowed for tracing. |

## Consequences

- Pointer frontmatter has `title` and `task_id` (`atlas://…/ULID`); no `display_slug` field.
- Index / list columns: title + ULID (and status etc.); not a kebab column.
- Migration must strip any kebab-as-id usage; see the hard-cut migrate pin.

## Provenance

Pinned by the maintainer on 2026-10-01, when Discuss continued after the identity-shape pins.
