---
type: document
title: "Proposal — atlas-todo v0.2 field model (awaiting pins)"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: in-discussion
kva: alive
reality: current
description: "Candidate skill-enforced fields for assignee, parent hierarchy, and blocked_by. Not a pin until the maintainer accepts."
tags: [atlas-todo, proposal, assignee, parent, blocked-by]
origin: derived
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations/research-tracker-models.md
    kind: backed_by
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Proposal (candidate)

Keep `type: task` + existing v1 fields (`todo_id`, `todo_status`, `body_path`, `related_node`). Add skill-enforced:

| Field | Required? | Shape | Meaning |
|---|---|---|---|
| `assignee` | no | string \| null | Who owns the work: human handle or agent path-slug (e.g. `docs-agent`, `octocat`). Self-assignment allowed. |
| `parent` | no | `todo_id` \| null | Exactly one parent TODO in the same Atlas. Tree hierarchy. |
| `blocked_by` | no | list of `todo_id` | TODOs that must reach `done` (or be cancelled) before this one is unblocked. Many-to-many. |

### Derived (do not dual-write as source of truth)

- **`sub_tasks`:** all pointers whose `parent` equals this `todo_id` (list path / index column).
- **`blocks`:** inverse of `blocked_by` (optional index convenience).
- **Blocked display:** true when any `blocked_by` target has `todo_status: open` (GitHub-style). Do **not** add `todo_status: blocked`.

### Migration

- Host Atlases that already use a core/domain `depends_on` key (for example existing consumer Atlases) map `depends_on` → `blocked_by` on the next update/complete/list path touch.
- Empty `assignee` / `parent` / `blocked_by` remain legal (v1 pages stay valid).

### Non-goals (this cut)

- Cross-Atlas parent or blocked_by targets (same-Atlas only in v0.2).
- Multi-assignee arrays (start singular; revisit if needed).
- Separate Depends vs Blocks link types (one dependency axis: `blocked_by`).
- Changing overlay SCHEMA to redeclare core `task` (still skill-enforced).

## Open cuts for pin

1. Singular `assignee` vs list `assignees`.
2. Parent-only canonical vs also storing `sub_tasks` lists on the parent.
3. Field name `blocked_by` (GitHub) vs keep/alias `depends_on` (ADO; existing consumer usage).
4. Derived blocked vs adding `todo_status: blocked`.
