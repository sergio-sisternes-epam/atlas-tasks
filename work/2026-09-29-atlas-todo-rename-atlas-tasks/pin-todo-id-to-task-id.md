---
type: decision
title: "Pin — rename pointer field todo_id → task_id"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
status: accepted
kva: alive
reality: current
description: "Living pin: skill-enforced pointer field todo_id becomes task_id everywhere in skill, overlay, and docs for atlas-tasks v0.3.0."
tags: [atlas-tasks, pin, task_id]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/pin-hard-cut-tasks-only.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
---

## Decision

Rename the skill-enforced pointer field **`todo_id` → `task_id`** everywhere in the skill, SCHEMA overlay, scenarios, and docs. No dual-read of `todo_id` after v0.3.0 (same hard-cut posture as the folder rename).

## Consequences

- Existing task pages must rename the key during migrate.
- Index columns, path docs, and smoke/adversarial scenarios update to `task_id`.
- `depends_on` entries remain ids of other tasks; docs refer to them as `task_id` values.

## Provenance

Approved by the maintainer on 2026-09-29.
