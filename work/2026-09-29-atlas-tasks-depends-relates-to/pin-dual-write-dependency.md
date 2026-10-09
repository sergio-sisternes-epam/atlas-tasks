---
type: decision
title: "Pin — dual-write dependency edges (waiter + blocker)"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: accepted
kva: alive
reality: current
description: "Living pin: skill dual-writes relates_to dependency on the waiting task and a reverse edge on the blocker; keeps both ends in sync."
tags: [atlas-tasks, pin, dependency, dual-write]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-remove-depends-on.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
---

## Decision

**Dual-write** dependency links: the waiting task gets `relates_to` → blocker with `kind: dependency`; the blocker gets a **reverse** `relates_to` → waiter. The skill keeps both ends in sync (add/update/remove). Cycles forbidden.

## Consequences

- List/index can discover dependents from the blocker without a full store scan.
- Reverse **kind** name still open (next pin).
- Same discipline as parent/`sub_tasks` dual-write.

## Provenance

Approved by the maintainer on 2026-09-29.
