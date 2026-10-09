---
type: protostar
title: "What is the exact atlas:// grammar for task_id?"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: closed
kva: superseded
growth: false
star_kind: question
reality: current
description: "Superseded by pin-atlas-uri-physical-path: task_id is atlas://<atlas_id>/tasks/<ULID> resolving to tasks/<ULID>.md."
tags: [atlas-tasks, protostar, ulid, atlas-uri, task-id, path]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-atlas-uri-physical-path.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Idea

Pin the exact `atlas://` URI grammar for the composite `task_id`: path form versus fragment form, and how the URI maps to the on-disk task pointer under the home Atlas.

## Why it matters

Wrong grammar breaks cross-Atlas resolve and migrate. Callers and the package cut need one canonical string shape.

## Next probe

Confirm with the maintainer whether the id points at the physical `tasks/<ULID>` pointer path or a fragment-style locator.

## Resolution

Answered 2026-10-01. Living pin: `discuss/atlas-tasks-ulid-atlas-uri/pin-atlas-uri-physical-path.md`.
