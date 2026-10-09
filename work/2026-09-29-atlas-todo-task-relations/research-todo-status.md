---
type: document
title: "Research — tracker status models vs atlas-todo todo_status"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: probed
kva: alive
description: "How GitHub, Jira, and ADO model lifecycle status; implications for a lean todo_status enum."
tags: [atlas-todo, research, todo_status]
origin: third-party
sensitivity: public
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations/pin-blocked-derived.md
    kind: related
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Content

### Current atlas-todo (v1)

`todo_status`: `open` | `done` | `cancelled`

Gap: no way to mark work that has started but is not finished. Blocked is already pinned as **derived** from `depends_on`, so it must not re-enter the enum.

### GitHub Issues

Binary **state**: `open` | `closed`. Close **reasons** (not separate statuses): `completed`, `not_planned`, `duplicate`. Richer lifecycle often lives in labels or derived signals (assignee = claimed, linked PR = waiting). Lesson: keep the core enum small; put nuance in reasons/derived fields.

### Jira

Unlimited named statuses, but every status maps to exactly one of **three categories**: To Do, In Progress, Done. Lesson: three buckets are the reporting spine; named statuses are optional flavour.

### Azure DevOps

States map to fixed **categories**: Proposed, In Progress, Resolved, Completed, Removed. Agile defaults often look like New → Active → Resolved → Closed (+ Removed). Lesson: proposed / active / done / removed covers most work; Resolved is optional verification.

## Lean recommendation for atlas-todo

Aim for **four** values (one more than today, still under ADO’s five):

| Value | Maps roughly to |
|---|---|
| `open` | GitHub open; Jira To Do; ADO Proposed |
| `in_progress` | Jira In Progress; ADO Active / In Progress |
| `done` | GitHub closed+completed; Jira/ADO Done/Completed |
| `cancelled` | GitHub closed+not_planned; ADO Removed / won’t do |

Out of enum (already decided or deferred): blocked (derived); deferred/on-hold (use open + note, or a later field); duplicate (cancel + body note).

## Provenance

Research 2026-09-29 during Discuss, after the maintainer asked to review the status count.
