---
type: decision
title: "Pin — the main index is a task list of lists and loose tasks"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: tasks/index.md is itself a task list. Its entries are other task lists or loose tasks that belong to no specific list."
tags: [atlas-tasks, pin, task-list, index]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-task-list-own-file.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-task-lists/protostar-index-shows-members.md
    kind: related
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

The main task index (`tasks/index.md`) is itself a task list.

It may contain other task lists, each in its own file and linked from this index. It may also contain loose tasks that do not belong to any specific list.

A task that belongs to a specific list is a member of that list file. It is not a loose task on the main index.

Rejected for this pin: the main index shows only list links, with no loose tasks. Also rejected: every member of every list is repeated as its own row on the main index.
