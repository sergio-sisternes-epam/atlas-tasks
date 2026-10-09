---
type: decision
title: "Pin — distributed means per-Atlas todo index + cross-Atlas coordination"
created: "2026-09-29"
work_id: "2026-09-28-atlas-todo-design"
status: accepted
kva: alive
reality: current
description: "Living pin: each Atlas holds todo/index.md; TODO pages live in local or remote Atlases; agents coordinate tasks across multiple Atlases."
tags: [atlas-todo, distributed, pin]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-28-atlas-todo-design/hub.md
    kind: derived_from
  - path: work/2026-09-28-atlas-todo-design/starting-thesis.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/protostar-what-distributed-means.md
    kind: kva_supersede
  - path: work/2026-09-28-atlas-todo-design.md
    kind: implements
---

## Decision

**Distributed** for atlas-todo means:

1. Each Atlas contains an index at `todo/index.md`.
2. TODO pages live across local or remote Atlases (not only inside one store).
3. Agents use that mesh to coordinate tasks across multiple Atlases.

## Consequences

- The discipline is cross-store: a consumer Atlas both hosts local TODOs and can see/coordinate TODOs that live elsewhere.
- Identity and linking of a TODO across Atlases become first-class design questions (next cuts).
- One-store multi-agent views alone are not the definition of distributed (may still be useful as a consumer pattern).

## Provenance

Approved by the maintainer on 2026-09-29 during the atlas-todo design discussion.
