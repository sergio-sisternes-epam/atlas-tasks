---
type: work
title: "Autogenesis work — depends via relates_to kind:dependency"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: done
description: "Canonical Autogenesis work for removing depends_on in favour of relates_to kind:dependency / blocks dual-write. Implemented as atlas-tasks v0.4.0 after v0.3.0 publish gate."
origin: derived
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
  - path: autogenesis/plans/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: derived_from
  - path: experiences/2026-09-29-atlas-tasks-depends-relates-to-implement.md
    kind: related
---

## Intent

Replace the dedicated `depends_on: []` field with Atlas-native `relates_to` edges: waiter `kind: dependency`, blocker dual-write `kind: blocks`. Derive list/index blocked from dependency targets using the v0.2 terminal rule. Fail closed unless targets are same-Atlas `type: task` pointer paths. Ship as atlas-tasks **v0.4.0** after the v0.3.0 rename publish gate.

## Status

`done` — implemented as atlas-tasks v0.4.0; plan closed. Experience: `experiences/2026-09-29-atlas-tasks-depends-relates-to-implement.md`.

## Done when

- [x] Discuss pins locked (remove depends_on; dual-write; kind blocks; task-pointer targets; derived blocked)
- [x] Autogenesis design plan persisted and compile green
- [x] Explicit maintainer approval + v0.3.0 tag gate satisfied
- [x] Implement: paths + README/overlay docs + smokes + adversarial v2; package 0.4.0
- [x] Plan status implemented; this work node done
