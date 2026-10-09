---
type: decision
title: "Pin — package and repo rename to atlas-tasks"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
status: accepted
kva: alive
reality: current
description: "Living pin: APM package name and GitHub repo become atlas-tasks (was atlas-todo)."
tags: [atlas-tasks, pin, rename]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
---

## Decision

Rename the APM package (`apm.yml` / `SKILL.md` name) and the GitHub repository `sergio-sisternes-epam/atlas-todo` to **`atlas-tasks`**.

## Consequences

- Install pin becomes `sergio-sisternes-epam/atlas-tasks#v…`.
- Downstream install references and Atlas mesh strings update to `atlas-tasks`.
- GitHub redirects from the old repo name remain until consumers retarget.

## Provenance

Approved by the maintainer on 2026-09-29 (full-align option: package + repository).
