---
type: decision
title: "Pin — TODO entity is a new skill with its overlay"
created: "2026-09-29"
work_id: "2026-09-28-atlas-todo-design"
status: accepted
kva: alive
reality: current
description: "Living pin: atlas-todo is a new Atlas skill plus a dedicated overlay so TODO operations behave as designed across Atlases."
tags: [atlas-todo, entity, skill, overlay, pin]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-28-atlas-todo-design/hub.md
    kind: derived_from
  - path: work/2026-09-28-atlas-todo-design/starting-thesis.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/pin-distributed-means.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/protostar-todo-entity-shape.md
    kind: kva_supersede
  - path: work/2026-09-28-atlas-todo-design.md
    kind: implements
---

## Decision

A TODO in atlas-todo is not merely a reuse of existing `task`/work pages. The capability is delivered as:

1. A **new Atlas skill** (`atlas-todo`).
2. A **dedicated overlay** that defines the types and contracts the skill operates against.

Together they make distributed TODO behaviour (per-Atlas `todo/index.md`, local/remote pages, cross-Atlas coordination) work as designed.

## Consequences

- Schema/overlay authoring is in scope for the package, not an afterthought.
- Skill paths and overlay types must stay aligned; consumers install both.
- Relation to existing `task` pages remains a separate open cut (reuse vs complement vs replace at the *content* level).

## Provenance

Approved by the maintainer on 2026-09-29 during the atlas-todo design discussion.
