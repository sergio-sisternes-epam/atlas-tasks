---
type: decision
title: "Pin — reverse edge kind is blocks"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: accepted
kva: alive
reality: current
description: "Living pin: blocker relates_to waiter with kind:blocks; waiter relates_to blocker with kind:dependency."
tags: [atlas-tasks, pin, blocks, dependency]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-dual-write-dependency.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
---

## Decision

Waiter → blocker: `relates_to` **`kind: dependency`**.  
Blocker → waiter: `relates_to` **`kind: blocks`**. Skill dual-writes and syncs both.

## Provenance

Approved by the maintainer on 2026-09-29.
