---
type: protostar
title: "Lift v0.4 cross-Atlas dependency non-goal — what may cross?"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: closed
kva: superseded
growth: false
star_kind: question
reality: current
description: "Superseded by pin-cross-atlas-dependency-scope: hierarchy same-Atlas; dependency/blocks may cross with fail-closed resolve."
tags: [atlas-tasks, protostar, hierarchy, dependency, cross-atlas]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-cross-atlas-dependency-scope.md
    kind: related
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Idea

Decide whether composite `task_id` lifts the v0.4 “cross-Atlas is a non-goal” line, and for which relations (`parent` / `sub_tasks` versus `kind:dependency` / `kind:blocks`).

## Why it matters

The traverse-Atlases objective needs dependency edges that can name a remote task, without breaking tree ownership if hierarchy were allowed to cross mounts.

## Next probe

Ask the maintainer for the hierarchy-versus-dependency split; record a living pin or keep the non-goal.

## Resolution

Answered 2026-10-01. Living pin: `discuss/atlas-tasks-ulid-atlas-uri/pin-cross-atlas-dependency-scope.md`.
