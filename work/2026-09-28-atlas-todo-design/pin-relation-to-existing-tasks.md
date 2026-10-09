---
type: decision
title: "Pin — build on core task; overlay extends as needed"
created: "2026-09-29"
work_id: "2026-09-28-atlas-todo-design"
status: accepted
kva: alive
reality: current
description: "Living pin: atlas-todo complements the existing Atlas task type; the overlay extends the core type as needed. It does not wholesale replace existing task pages or human-in-the-loop (HITL) review queues."
tags: [atlas-todo, task, overlay, hitl, pin]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-28-atlas-todo-design/hub.md
    kind: derived_from
  - path: work/2026-09-28-atlas-todo-design/starting-thesis.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/pin-todo-entity-shape.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/protostar-relation-to-existing-tasks.md
    kind: kva_supersede
  - path: work/2026-09-28-atlas-todo-design.md
    kind: implements
---

## Decision

atlas-todo **builds on the existing Atlas `task` type**. A dedicated overlay **extends** that core as needed for distributed TODO behaviour (`todo/index.md`, local/remote placement, cross-Atlas coordination).

This is **complement / extend**, not a wholesale replacement of `task` pages that other overlays already keep, or of human-in-the-loop (HITL) review queues built on them.

## Consequences

- Overlay fields and skill paths should assume `task` as the base contract.
- Existing `task` pages and HITL queues keep using `task` unchanged; atlas-todo adds the distributed index and coordination layer on top.
- Pin on “new skill + overlay” still holds: the overlay extends core `task`, it does not invent a parallel unrelated type family without need.

## Provenance

Approved by the maintainer on 2026-09-29 during the atlas-todo design discussion.
