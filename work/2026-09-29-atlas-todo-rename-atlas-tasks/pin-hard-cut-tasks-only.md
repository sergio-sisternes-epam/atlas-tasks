---
type: decision
title: "Pin — hard cut to tasks/ only in v0.3.0"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
status: accepted
kva: alive
reality: current
description: "Living pin: atlas-tasks v0.3.0 requires tasks/ and tasks/index.md only; no todo/ read shim; document migrate steps for consumers."
tags: [atlas-tasks, pin, hard-cut, migrate]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/pin-overlay-todo-to-tasks.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
---

## Decision

**Hard cut** at **v0.3.0**: the skill requires `tasks/` + `tasks/index.md` only. There is **no** read shim for legacy `todo/`. Release notes and skill migrate path document the one-shot rename (`todo/` → `tasks/`, update index path, reinstall package pin).

## Consequences

- Atlases still on `todo/index.md` fail closed until migrated (including consumer Atlases that had just adopted the v0.2 `todo/` surface).
- Implement must ship explicit migrate steps (manual rename + index rewrite + package retarget).
- Semver is breaking **0.3.0**; do not publish as a patch on 0.2.x.

## Provenance

Approved by the maintainer on 2026-09-29.
