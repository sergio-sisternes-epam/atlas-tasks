---
type: work
title: "depends_on → relates_to kind:dependency"
created: 2026-09-29
work_id: 2026-09-29-atlas-tasks-depends-relates-to
status: done
description: "Depends_on removed; waits via relates_to kind:dependency / blocks dual-write. Implemented as atlas-tasks v0.4.0 after v0.3.0 rename gate."
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: related
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: follows
  - path: autogenesis/plans/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
  - path: autogenesis/work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
---

## Scope

Replace (or supersede) the v0.2 `depends_on: []` field with Atlas-native `relates_to` edges using `kind: dependency`. Derived blocked recomputes from those edges. Implement after atlas-tasks v0.3.0 rename ships.

## Status

`done` — Autogenesis implement landed as atlas-tasks v0.4.0.

## Outcome

Implement landed as the v0.4.0 implementation change (pre-publication history). See `experiences/2026-09-29-atlas-tasks-depends-relates-to-implement.md`.
