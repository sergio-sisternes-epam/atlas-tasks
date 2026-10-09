---
type: decision
title: "Pin — hierarchy dual-writes parent and sub_tasks"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: accepted
kva: alive
reality: current
description: "Living pin: atlas-todo v0.2 stores both parent on the child and sub_tasks on the parent; skill paths must keep them in sync. One parent per TODO (tree)."
tags: [atlas-todo, pin, parent, sub_tasks]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations/proposal-field-model.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations/pin-assignees-list.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Decision

Hierarchy is **dual-written**:

- Child pointer: optional `parent: <todo_id>` (exactly one parent, or null).
- Parent pointer: optional `sub_tasks: [<todo_id>, ...]` listing children.

Skill **add** / **update** / **complete** paths that change either side must update the other so the two views stay consistent. Cycles are forbidden.

## Consequences

- Agents may navigate from either end without scanning the whole index.
- Drift is a skill bug: paths own sync integrity (fail closed on conflict rather than silent diverge).
- Still a tree: one parent maximum per TODO.

## Provenance

Approved by the maintainer on 2026-09-29 (cut 2 of 4), overriding the parent-only recommendation in the field proposal.
