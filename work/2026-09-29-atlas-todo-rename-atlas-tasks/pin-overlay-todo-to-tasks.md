---
type: decision
title: "Pin — overlay surface todo/ → tasks/"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
status: accepted
kva: alive
reality: current
description: "Living pin: on-disk overlay and index move from todo/ and todo/index.md to tasks/ and tasks/index.md."
tags: [atlas-tasks, pin, overlay, tasks]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/pin-package-repo-atlas-tasks.md
    kind: follows
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
---

## Decision

Move the overlay surface from **`todo/`** + **`todo/index.md`** to **`tasks/`** + **`tasks/index.md`**. Skill paths, SCHEMA overlay package folder, and consumer Atlases migrate accordingly.

## Consequences

- Breaking for every Atlas already using `todo/index.md` (for example consumer Atlases that migrated to v0.2).
- Contribution / overlay id strings that embed `todo` rename to `tasks` where they name the surface.
- Core OKF type remains `task`; this pin is about the discipline folder and index, not renaming the OKF type.

## Provenance

Approved by the maintainer on 2026-09-29 (full-align option: package name + `todo/` → `tasks/`).
