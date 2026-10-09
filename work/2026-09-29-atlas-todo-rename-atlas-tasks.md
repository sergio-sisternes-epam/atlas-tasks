---
type: work
title: "Rename atlas-todo → atlas-tasks (package, repo, overlay surface)"
created: 2026-09-29
work_id: 2026-09-29-atlas-todo-rename-atlas-tasks
status: done
description: "Breaking rename of the APM package to atlas-tasks and of the overlay surface todo/ → tasks/, shipped as v0.3.0. The GitHub repository rename and release tag followed the content change."
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: related
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: follows
  - path: work/2026-09-29-atlas-todo.md
    kind: follows
  - path: autogenesis/plans/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: related
  - path: autogenesis/work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: related
  - path: experiences/2026-09-29-atlas-todo-rename-atlas-tasks-implement.md
    kind: related
---

## Scope

Rename the package and GitHub repository from `atlas-todo` to `atlas-tasks`, and move the on-disk overlay surface from `todo/` + `todo/index.md` to `tasks/` + `tasks/index.md`. Discuss memory stays on the existing Atlas id (`github.com/sergio-sisternes-epam/atlas-todo`) until the repository rename lands; thereafter the store and consumers use `github.com/sergio-sisternes-epam/atlas-tasks`.

## Status

`done` — package content rename landed as the v0.3.0 implementation change (pre-publication history). Repository rename, release tag and the migration notice to consumer Atlases were follow-up release steps.

## Outcomes

- Discuss target confirmed: `github.com/sergio-sisternes-epam/atlas-todo` (ref `atlas`, shared) until the rename.
- Full-align scope locked by the maintainer: package + repository + `todo/` → `tasks/`.
- Product identity `atlas-tasks` v0.3.0 implemented (hard cut; migrate docs; adversarial scenarios v1).
