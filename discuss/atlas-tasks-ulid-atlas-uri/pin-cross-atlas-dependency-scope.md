---
type: decision
title: "Pin — parent/sub_tasks same-Atlas; dependency/blocks may cross"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: accepted
kva: alive
reality: current
description: "Living pin: hierarchy (parent/sub_tasks) stays same-Atlas only; kind:dependency and kind:blocks may target tasks in other Atlases (fail-closed resolve)."
tags: [atlas-tasks, pin, hierarchy, dependency, cross-atlas]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-cross-atlas-dependency-scope.md
    kind: kva_supersede
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-cross-atlas-reverse-edge.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Decision

Lift the v0.4 “cross-Atlas is a non-goal” line **only for dependency edges**, with this split:

| Relation | Scope |
| --- | --- |
| `parent` / `sub_tasks` (hierarchy) | **Same-Atlas only.** Cross-Atlas parent or child → fail closed. |
| `relates_to` `kind:dependency` / `kind:blocks` | **May cross Atlases.** Target is a task identity (`atlas://…/ULID` or a pointer that resolves to one). |

**Fail-closed resolve** remains mandatory for every cross-Atlas dependency/blocks target: unknown, unmounted, or unreadable home store must **not** silently treat the edge as satisfied (blocked derivation stays conservative / unresolved → blocked or error per path contract, never “ok because missing”).

Same-Atlas dependency/blocks targets remain valid.

This pin locks **Atlas-boundary allowance** and fail-closed resolve only. It does **not** decide whether a remote `kind:dependency` requires a coordinated reverse `kind:blocks` write on the foreign Atlas (see [protostar-cross-atlas-reverse-edge.md](protostar-cross-atlas-reverse-edge.md)). Same-Atlas dual-write (`pin-dual-write-dependency` / `pin-reverse-kind-blocks`) stays authoritative inside one store.

## Rationale

Composite `task_id` exists so a dependency can name a task whose home store is elsewhere. Hierarchy is a tree inside one Atlas overlay; allowing cross-Atlas parents would split ownership and dual-write sync across mounts. Dependency is a graph edge and can point out.

## Alternatives considered

| Option | Shape | Why not (this pin) |
| --- | --- | --- |
| Keep all relations same-Atlas | Composite id forward-compat only | Underuses the id pin; blocks the traverse-Atlases objective. |
| Allow cross-Atlas parent/sub_tasks | Full hierarchy across stores | Ownership and dual-write sync become undefined. |
| Split (chosen) | Hierarchy local; dependency may cross | Matches the objective without breaking tree ownership. |

## Consequences

- Supersedes the v0.4 pin “dependency/blocks targets are same-Atlas task pointers only” **for Atlas-boundary scope** (targets remain `type: task` pointers / task ids; body files and non-task notes such as reviewer or sign-off pages still fail closed).
- Package steward cut must teach resolve + fail-closed for remote `atlas://` dependency targets.
- Supersedes the open question in [protostar-cross-atlas-dependency-scope.md](protostar-cross-atlas-dependency-scope.md).
- **Open:** cross-Atlas reverse-edge / dual-write semantics (one-way vs coordinated `kind:blocks`, failure/retry) — [protostar-cross-atlas-reverse-edge.md](protostar-cross-atlas-reverse-edge.md). Not locked here.

## Provenance

Pinned by the maintainer during design review on 2026-10-01: parent and sub_tasks stay same-Atlas; dependency and blocks may cross. Recorded on the `atlas` branch the same day.
