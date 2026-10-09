---
type: decision
title: "Pin — install APM package; mount overlay on user-named Atlas"
created: "2026-09-29"
work_id: "2026-09-28-atlas-todo-design"
status: accepted
kva: alive
reality: current
description: "Living pin: consumers install atlas-todo as an APM package, then mount the overlay onto the specific Atlas the user indicates."
tags: [atlas-todo, packaging, mount, pin]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-28-atlas-todo-design/hub.md
    kind: derived_from
  - path: work/2026-09-28-atlas-todo-design/starting-thesis.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/pin-todo-entity-shape.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/protostar-skill-package-shape.md
    kind: kva_supersede
  - path: work/2026-09-28-atlas-todo-design.md
    kind: implements
---

## Decision

Consumers get atlas-todo by:

1. **Installing the APM package** (this repo as the skill package).
2. **Mounting the overlay** onto the **specific Atlas the user indicates** (not a fixed default foreign store).

## Consequences

- Package boundary is this repository; the general-purpose APM authoring toolkit stays a separate install.
- Overlay install is per chosen Atlas target — explicit user indication required.
- No silent writes into a shared discussion Atlas or another agent’s store.

## Provenance

Approved by the maintainer on 2026-09-29 during the atlas-todo design discussion.
