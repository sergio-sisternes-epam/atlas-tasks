---
type: decision
title: "Pin — every task list is its own file, linked from the main index"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: any task list has its own file, linked to the main atlas-tasks index. A parent task is not a substitute for that file."
tags: [atlas-tasks, pin, task-list]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-task-lists/current-reality.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/protostar-list-vs-parent.md
    kind: related
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

Any task list has its own file. That file is linked from the main atlas-tasks index (`tasks/index.md`). A parent task with children is not a task list.

Rejected for this pin: using only `parent` and `sub_tasks` as the list, with no list file.

## Still open

Whether each member task also appears as its own row on the main index, besides the link to the list file. Frontmatter on the task and on the list still both need to know the membership. That awareness is part of the objective and is not yet shaped.
