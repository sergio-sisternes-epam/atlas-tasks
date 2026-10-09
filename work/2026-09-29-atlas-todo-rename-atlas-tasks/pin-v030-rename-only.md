---
type: decision
title: "Pin — v0.3.0 is rename-only; defer depends_on fixes"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
status: accepted
kva: alive
reality: current
description: "Living pin: atlas-tasks v0.3.0 ships only the rename (package/repo/surface/fields). depends_on issues reported from a consumer Atlas are out of scope until after v0.3.0."
tags: [atlas-tasks, pin, scope]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
---

## Decision

**v0.3.0 focuses solely on the rename** (package/repo → `atlas-tasks`, overlay `todo/` → `tasks/`, `todo_id` → `task_id`, `todo_status` → `task_status`, hard cut, migrate docs). **Do not** change `depends_on` semantics or fix the `depends_on` problem reported from a consumer Atlas (see [the dependency write-up](../2026-09-29-atlas-tasks-depends-relates-to/problem-dependency-writeup.md)) in this release. That work waits until after v0.3.0 is out.

## Consequences

- Autogenesis design/implement for this work_id must not expand into dependency-model changes.
- A follow-on work item after publish addresses the consumer’s `depends_on` findings (`work/2026-09-29-atlas-tasks-depends-relates-to.md`).

## Provenance

Approved by the maintainer on 2026-09-29.
