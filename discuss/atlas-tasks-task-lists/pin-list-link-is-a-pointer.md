---
type: decision
title: "Pin — a list links another list by pointer, not by copying tasks"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: when a task list points at another task list, that entry is only a pointer. Member tasks are not copied."
tags: [atlas-tasks, pin, task-list, pointer]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-membership-both-sides.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

When a task list points at another task list, that entry is only a pointer. The tasks that belong to the other list stay in that list's file. They are not copied into the pointing list.

The main index follows the same rule. For example, a link to a “Release 2.0” list is a pointer to that list file, not a copy of the release's tasks.
