---
type: experience
title: "Problem — dependency write-up from a consumer Atlas"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: open
kva: alive
reality: current
description: "Filed problem: a dedicated depends_on[] list duplicated the Atlas graph and drifted. Waits should be relates_to kind:dependency, with derived blocked recomputed from those edges."
tags: [atlas-tasks, problem, depends_on]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
---

## Claim

A dedicated `depends_on: []` field is the wrong shape. Task dependencies should be ordinary Atlas links — `relates_to` with `kind: dependency` — so tasks and knowledge share one graph. The maintainer confirmed this intent after a consumer Atlas reported the problem against v0.2.

## Evidence (synthetic example of the reported shape)

The consumer Atlas used v0.2 fields as designed. Its real pages are not reproduced here; this neutral example has the same structure.

- **T15** "Tag release candidate" and **T16** "Publish release notes". T16 cannot start until T15 is done.
- **T16 today (v0.2 shape):** the wait is stored twice — once as an id in `depends_on`, once as a path in `relates_to`. The index shows `blocked: yes`, derived from `depends_on` only.

  ```yaml
  # tasks/t16-publish-release-notes.md (v0.2)
  todo_id: t16-publish-release-notes
  todo_status: open
  depends_on: [t15-tag-release-candidate]
  relates_to:
    - path: tasks/t15-tag-release-candidate.md
      kind: related
  ```

- **Drift:** the two references are edited by different paths. When the predecessor changes (for example T15 is cancelled and replaced by a new release-candidate task), one reference is updated and the other is not, so the derived `blocked` column and the knowledge graph disagree.
- **Expected:** drop `depends_on`; the wait on T15 is a single typed edge.

  ```yaml
  relates_to:
    - path: tasks/t15-tag-release-candidate.md
      kind: dependency
  ```

- **Same pattern elsewhere:** T10→T09, T11→T10, T13→T12, and one further pair of release tasks.
- **Non-task waits stay prose.** Waiting on an outside party (for example a sign-off from an outside reviewer) is not a task and must not become a fake `kind: dependency` edge to a reviewer or sign-off note.

## Confusion named

1. Two link systems (task wait vs related memory).
2. Path vs id duplication for the same predecessor.
3. Derived blocked must move with the edge model.
4. `blocked_by` stays prose-only; the edge is the structured form.
5. Fail closed if `kind: dependency` targets non-tasks.

## Timing

Discuss + design now; implement after the **atlas-tasks v0.3.0** rename.
