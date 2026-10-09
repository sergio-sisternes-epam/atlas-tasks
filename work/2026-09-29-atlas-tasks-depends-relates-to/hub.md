---
type: experience
title: "Hub — depends via relates_to kind:dependency"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: done
kva: alive
reality: current
description: "discussion_root for moving task dependencies from depends_on field to relates_to kind:dependency."
tags: [atlas-tasks, discuss, depends_on, relates_to, dependency]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
  - path: work/2026-09-29-atlas-todo-task-relations/pin-depends-on-canonical.md
    kind: related
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/problem-dependency-writeup.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-remove-depends-on.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-dual-write-dependency.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-reverse-kind-blocks.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-targets-task-pointers-only.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-derived-blocked-from-dependency.md
    kind: follows
---

## Context

A consumer Atlas running v0.2 reported that the dedicated `depends_on: []` list duplicated the Atlas graph and drifted from it. The maintainer's intent: no dedicated dependency list. Waits are expressed like any other Atlas link — `relates_to` with `kind: dependency`. Representative example: T16 waits on T15; the same pattern appeared on several other task pairs. See [Problem — dependency write-up from a consumer Atlas](problem-dependency-writeup.md).

## Orbit

Pins complete; Autogenesis design approved; implement landed as atlas-tasks v0.4.0.
