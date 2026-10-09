---
type: decision
title: "Pin — task_list on the task, tasks on the list"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: a task uses task_list (omitted when loose). A list uses tasks, and each member is a pointer."
tags: [atlas-tasks, pin, task-list, frontmatter]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-membership-both-sides.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-list-link-is-a-pointer.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/protostar-membership-field-names.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

On a task, the field is `task_list`. It holds one pointer to that task's list. Omit it when the task is loose. It is not `parent`, and it is not a copy of the list.

On a task list, the field is `tasks`. Each entry is a pointer. A member may be a task or another task list. Pointing at a list does not copy that list's tasks.

The main index is a task list, so it uses `tasks` the same way.

## Not pinned

The file path and id shape of a task-list page. `task_list` and `tasks` name the link. They do not choose where the list file lives.
