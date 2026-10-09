---
type: decision
title: "Pin — dependency field is depends_on"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: accepted
kva: alive
reality: current
description: "Living pin: atlas-todo v0.2 canonical dependency list is depends_on: [todo_id]. blocked_by is docs-only language, not a second field."
tags: [atlas-todo, pin, depends_on]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations/proposal-field-model.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations/pin-hierarchy-dual-write.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Decision

Canonical dependency field is **`depends_on`**: optional list of `todo_id` values this TODO waits on. Aligns with the `depends_on` key that consumer and domain Atlases already used, and with the Azure DevOps predecessor sense.

`blocked_by` may appear in human prose or help text as synonym; it is **not** a second stored field.

## Consequences

- Skill contract and index columns use `depends_on`.
- Existing pages that already carry `depends_on` need no rename.
- Inverse “blocks” remains derived for list/help if useful.

## Provenance

Approved by the maintainer on 2026-09-29 (cut 3 of 4). Superseded for v0.4.0 by `work/2026-09-29-atlas-tasks-depends-relates-to/pin-remove-depends-on.md`.
