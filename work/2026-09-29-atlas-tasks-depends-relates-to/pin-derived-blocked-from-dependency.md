---
type: decision
title: "Pin — derived blocked from kind:dependency (v0.2 terminal rule)"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: accepted
kva: alive
reality: current
description: "Living pin: derive blocked by scanning waiter kind:dependency targets; blocked while any target task_status is open|in_progress; done|cancelled clear. No blocked status/boolean."
tags: [atlas-tasks, pin, blocked, dependency]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-remove-depends-on.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-task-relations/pin-blocked-derived.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
---

## Decision

**Derived blocked** (list/index only, not a stored field or `task_status`): scan the waiter’s `relates_to` edges with **`kind: dependency`**. Blocked while **any** target’s `task_status` is `open` or `in_progress`. Targets that are `done` or `cancelled` do **not** block. Empty dependency set → not blocked. Same terminal rule as v0.2 `depends_on`; only the edge source changed.

## Provenance

Defaulted on 2026-09-29 when the blocked-rule question was skipped during Discuss. It matches the prior accepted pin `pin-blocked-derived` and the [consumer write-up](problem-dependency-writeup.md) (recompute from dependency edges). The maintainer may override it.
