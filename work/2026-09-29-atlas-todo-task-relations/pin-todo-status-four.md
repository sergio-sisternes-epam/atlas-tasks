---
type: decision
title: "Pin — todo_status is open | in_progress | done | cancelled"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: accepted
kva: alive
reality: current
description: "Living pin: four todo_status values. Duplicate is cancelled plus relates_to the surviving TODO, not a fifth status."
tags: [atlas-todo, pin, todo_status]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations/research-todo-status.md
    kind: backed_by
  - path: work/2026-09-29-atlas-todo-task-relations/pin-blocked-derived.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Decision

`todo_status` enum is exactly:

`open` | `in_progress` | `done` | `cancelled`

**Duplicate** is not a status. Mark the discarded TODO `cancelled` and link it with `relates_to` (kind appropriate, e.g. `related` or a skill-documented duplicate kind if we later name one) to the surviving TODO.

Blocked remains derived from `depends_on` (separate pin).

## Consequences

- v1 `open|done|cancelled` pages stay valid; `in_progress` is additive.
- complete path still targets `done`; cancel path / update may set `cancelled`.
- add defaults to `open`; update may move to `in_progress`.

## Provenance

Approved by the maintainer on 2026-09-29 (cut 5, added after the status-count research).
