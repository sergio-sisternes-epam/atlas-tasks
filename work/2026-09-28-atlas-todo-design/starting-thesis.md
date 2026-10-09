---
type: document
title: "Starting thesis — atlas-todo as a new Atlas discipline"
created: "2026-09-28"
work_id: "2026-09-28-atlas-todo-design"
status: in-discussion
kva: alive
reality: current
description: "Completed initial thesis for atlas-todo: new Atlas skill + discipline for distributed Atlas TODO; Discuss-first fence locked; open distinctions sprouted as protostars. Autogenesis deferred."
tags: [atlas-todo, starting-thesis, atlas-discipline]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-28-atlas-todo-design.md
    kind: implements
  - path: work/2026-09-28-atlas-todo-design/hub.md
    kind: derived_from
  - path: work/2026-09-28-atlas-todo-design/protostar-what-distributed-means.md
    kind: related
  - path: work/2026-09-28-atlas-todo-design/pin-distributed-means.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/protostar-todo-entity-shape.md
    kind: related
  - path: work/2026-09-28-atlas-todo-design/protostar-relation-to-existing-tasks.md
    kind: related
  - path: work/2026-09-28-atlas-todo-design/protostar-skill-package-shape.md
    kind: related
---

## Content

### Stated intent

Build a new Atlas skill named **atlas-todo**. It should include a **new Atlas discipline** that provides a **distributed Atlas TODO** capability.

### Process fence (locked)

1. Install the APM authoring toolkit — **done**.
2. Package repository `sergio-sisternes-epam/atlas-todo` (renamed `atlas-tasks` in v0.3.0) — **done**.
3. Shared Atlas on consumer branch `atlas` — **done** (store id then `github.com/sergio-sisternes-epam/atlas-todo`).
4. Discuss write target confirmed — **done**.
5. **Discuss first**; **do not start Autogenesis** until durable criteria live in this store.

### Scaffold facts (current reality)

- Store: the `atlas` branch of the package repository, mounted locally under `<atlas-root>`.
- Mesh: single shared store, ref `atlas`.
- Branch `atlas` is PR-protected; design commits land via pull request into `atlas`.

### Distinctions

1. What “distributed” means — **pinned** (`pin-distributed-means.md`): each Atlas has `todo/index.md`; TODOs live in local or remote Atlases; agents coordinate across multiple Atlases.
2. What a TODO is in Atlas/OKF terms — **pinned** (`pin-todo-entity-shape.md`): new skill + dedicated overlay.
3. Relation to existing `task` pages and human-in-the-loop (HITL) queues — **pinned** (`pin-relation-to-existing-tasks.md`): build on core `task`; overlay extends; complement not replace.
4. Skill package shape / consumer mount — **pinned** (`pin-skill-package-shape.md`): install APM package; mount overlay on user-named Atlas.
5. Where TODO bodies live — **pinned** (`pin-todo-colocation.md`): colocated with related Atlas nodes; `task`/index are pointers.

### Non-goals for this thesis

- Running Autogenesis design or implement.
- Shipping marketplace packaging or CI release gates yet.
- Replacing discuss v0.5.0 project-Atlas rules.

## Provenance

Requested by the maintainer on 2026-09-28; Discuss target confirmed and the initial thesis completed the same day. Distinctions were pinned on 2026-09-29.

## Related

- hub: `work/2026-09-28-atlas-todo-design/hub.md`
- protostars listed in frontmatter `relates_to`
