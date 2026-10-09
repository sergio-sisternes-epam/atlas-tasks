---
type: decision
title: "Pin — blocked is derived from depends_on"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: accepted
kva: alive
reality: current
description: "Living pin: do not add todo_status blocked. Blocked display is true when any depends_on target is still open."
tags: [atlas-todo, pin, blocked, depends_on]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations/pin-depends-on-canonical.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Decision

**Blocked is derived.** A TODO is treated as blocked when any `depends_on` target still has an open (non-terminal) `todo_status`. Do not add `todo_status: blocked` and do not add a separate `blocked` boolean.

## Consequences

- `todo_status` stays a process enum only.
- List/index may show a derived blocked column for operators.
- Consumer Atlases that marked waits with `status: blocked` migrate to `open` plus a `depends_on` entry.

## Provenance

Approved by the maintainer on 2026-09-29 (cut 4 of 4).
