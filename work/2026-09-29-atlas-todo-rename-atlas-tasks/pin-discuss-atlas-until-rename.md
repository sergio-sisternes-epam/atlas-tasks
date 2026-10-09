---
type: decision
title: "Pin — discuss stays on atlas-todo Atlas until repo rename"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
status: accepted
kva: alive
reality: current
description: "Living pin: discuss memory for this rename uses github.com/sergio-sisternes-epam/atlas-todo (ref atlas) until the repo is renamed; thereafter atlas-tasks."
tags: [atlas-tasks, pin, atlas-id]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
---

## Decision

Confirm discuss target **`github.com/sergio-sisternes-epam/atlas-todo`** (ref `atlas`, shared) for this rename work while the repo still has that name. After the GitHub rename, the store id and mesh become **`github.com/sergio-sisternes-epam/atlas-tasks`**.

## Consequences

- No premature remount to a non-existent atlas-tasks remote.
- Implement plan must include mesh / submodule path update when the repo rename lands.

## Provenance

Approved by the maintainer on 2026-09-29: keep using the `atlas-todo` id while the repository still has that name, and move to `atlas-tasks` once it is renamed.
