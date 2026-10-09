---
type: protostar
title: "Cross-Atlas dependency reverse-edge / dual-write"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: open
kva: forming
growth: true
star_kind: question
reality: current
description: "Open: whether remote kind:dependency requires coordinated kind:blocks reverse writes on the foreign Atlas, including failure/retry — not locked by the cross-Atlas scope pin."
tags: [atlas-tasks, protostar, cross-atlas, dependency, blocks, dual-write]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-cross-atlas-dependency-scope.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-dual-write-dependency.md
    kind: related
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-reverse-kind-blocks.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Idea

Decide how the same-Atlas **dual-write** contract (`kind:dependency` on the waiter + `kind:blocks` on the blocker) extends when the dependency **target lives in another Atlas**.

The cross-Atlas scope pin already allows naming a remote task and requires fail-closed resolve. It does **not** lock reverse-edge writes across stores.

## Why it matters

Same-Atlas pins require every dependency to create and sync a reverse `kind:blocks` edge on the blocker. A remote dependency therefore may entail writing a second Atlas (and handling read-only mounts / partial failures). Leaving that undefined lets implementations produce incompatible graphs (one-way remote edges vs coordinated dual-write).

## Open cuts (do not decide alone)

1. **One-way vs dual-write** — may a cross-Atlas `kind:dependency` exist without a remote `kind:blocks`, or must both ends always be written?
2. **Write authority** — who may mutate the foreign Atlas (skill on the waiter’s host, package steward contract, maintainer-gated sync)?
3. **Failure / retry** — when the reverse write fails (unmounted, read-only, conflict), fail closed the forward edge, queue retry, or leave an explicit partial state?
4. **Sync / remove** — how add/update/remove stays consistent across two stores without inventing a cross-Atlas transaction.

## Next probe

Ask the maintainer (or the package steward once the maintainer unlocks it) which cuts are required before Autogenesis; record a living pin or terminate losing frames. Same-Atlas dual-write pins remain authoritative inside one Atlas.
