---
type: decision
title: "Pin — ownership is assignees list"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: accepted
kva: alive
reality: current
description: "Living pin: atlas-todo v0.2 uses optional assignees: [] of human handles or agent path-slugs (self allowed). Not a singular assignee field."
tags: [atlas-todo, pin, assignees]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations/proposal-field-model.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Decision

Ownership is stored as optional **`assignees`**: a list of strings (human handle or agent path-slug). Self-assignment is allowed. Empty list or omitted field means unassigned.

## Consequences

- Skill add/update/list paths treat `assignees` as a list, never a singular `assignee` key.
- Multi-owner TODOs (several agents or humans) are first-class.
- Index may show a compact assignees column (join) without changing the pointer contract.

## Provenance

Approved by the maintainer on 2026-09-29 (cut 1 of 4).
