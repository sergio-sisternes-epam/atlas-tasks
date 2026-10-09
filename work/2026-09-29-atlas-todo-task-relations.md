---
type: work
title: "Design atlas-todo v0.2 — assignee, hierarchy, blocked-by"
created: 2026-09-29
work_id: 2026-09-29-atlas-todo-task-relations
status: done
description: "Discuss + Autogenesis design for assignee, parent/sub-task hierarchy, and depends_on dependencies on atlas-todo pointers. Informed by Jira, Azure DevOps, and GitHub Issues. Design complete; awaiting approval to implement."
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: related
  - path: work/2026-09-29-atlas-todo.md
    kind: follows
  - path: work/2026-09-28-atlas-todo-design/hub.md
    kind: related
  - path: autogenesis/plans/2026-09-29-atlas-todo-task-relations.md
    kind: related
  - path: autogenesis/work/2026-09-29-atlas-todo-task-relations.md
    kind: related
---

## Scope

Extend the atlas-todo skill contract (still skill-enforced on `type: task`) with ownership and relationship fields: assignees list, parent/sub_tasks dual-write, and depends_on with derived blocked. Discussion pins complete; Autogenesis design persisted.

## Status

`done` — implement landed (v0.2.0); see experiences/2026-09-29-atlas-todo-task-relations-implement.md. Plan at `autogenesis/plans/2026-09-29-atlas-todo-task-relations.md`; implementing after explicit approval.

## Outcomes

- Discuss target confirmed: `github.com/sergio-sisternes-epam/atlas-todo` (ref `atlas`, shared; pre-rename store id).
- Research notes comparing Jira / ADO / GitHub Issues filed.
- Field proposal drafted; five pins landed (assignees; hierarchy dual-write; depends_on; blocked derived; todo_status four + duplicate via cancelled+relates_to).
- Autogenesis design plan written; compile required green; disposition awaiting-approval.

## Related

- discussion_root: `work/2026-09-29-atlas-todo-task-relations/hub.md`
- plan: `autogenesis/plans/2026-09-29-atlas-todo-task-relations.md`
- Autogenesis work: `autogenesis/work/2026-09-29-atlas-todo-task-relations.md`
