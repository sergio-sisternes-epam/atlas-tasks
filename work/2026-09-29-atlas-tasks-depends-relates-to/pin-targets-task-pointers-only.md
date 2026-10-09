---
type: decision
title: "Pin — dependency/blocks targets are same-Atlas task pointers only"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: accepted
kva: alive
reality: current
description: "Living pin: kind dependency/blocks may only target same-Atlas type:task pointer paths; fail closed on body files, non-task notes (reviewers, sign-offs), and cross-Atlas targets."
tags: [atlas-tasks, pin, dependency, targets]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/pin-reverse-kind-blocks.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
---

## Decision

`kind: dependency` and `kind: blocks` targets **must** be **same-Atlas** pages with **`type: task`** that are skill task **pointers** — not body files, and not non-task notes such as reviewer or sign-off pages. Unknown, wrong type, body_path-only, or cross-Atlas → **fail closed**.

## Provenance

Approved by the maintainer on 2026-09-29. A wait on an outside party stays prose on the task body, as described in the [consumer write-up](problem-dependency-writeup.md).
