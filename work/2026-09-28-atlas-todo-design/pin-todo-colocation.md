---
type: decision
title: "Pin — TODOs colocated with Atlas nodes; task/index as pointers"
created: "2026-09-29"
work_id: "2026-09-28-atlas-todo-design"
status: accepted
kva: alive
reality: current
description: "Living pin: TODO bodies live next to the Atlas nodes they concern; existing task pages (and todo/index.md) act as pointers into that colocated work."
tags: [atlas-todo, colocation, task, index, pin]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-28-atlas-todo-design/hub.md
    kind: derived_from
  - path: work/2026-09-28-atlas-todo-design/pin-distributed-means.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/pin-relation-to-existing-tasks.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design.md
    kind: implements
---

## Decision

TODO **bodies** live **close to the Atlas nodes they are about** (work, decisions, experiences, and similar). Existing **`task` pages act as pointers** into that colocated work. The per-Atlas **`todo/index.md`** is part of that pointer mesh (not the sole home of TODO content).

## Consequences

- Creating a TODO should place durable content beside related knowledge, then register a pointer via `task` / index.
- Cross-Atlas coordination follows pointers and indexes; it does not require dumping all TODO prose into a central queue folder.
- Aligns with “build on core `task`” and “distributed = index + local/remote pages.”

## Provenance

Approved by the maintainer on 2026-09-29 after the colocation idea was confirmed in Discuss.
