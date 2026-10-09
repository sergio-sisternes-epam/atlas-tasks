---
type: decision
title: "Pin — rename todo_status → task_status"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
status: accepted
kva: alive
reality: current
description: "Living pin: field todo_status becomes task_status; enum remains open|in_progress|done|cancelled."
tags: [atlas-tasks, pin, task_status]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/pin-todo-id-to-task-id.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
---

## Decision

Rename **`todo_status` → `task_status`**. Enum values stay **`open | in_progress | done | cancelled`**. No dual-read of `todo_status` after v0.3.0.

## Consequences

- Migrate docs rewrite the key on every task page.
- Skill list/filter paths and scenarios use `task_status`.
- Duplicate rule still: `cancelled` + `relates_to` survivor.

## Provenance

Approved by the maintainer on 2026-09-29.
