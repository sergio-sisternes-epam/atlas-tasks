---
type: decision
title: "Pin — a task list id is a ULID, like a task"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: a task-list file uses a ULID, the same identity shape as a task."
tags: [atlas-tasks, pin, task-list, ulid]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-list-lives-anywhere.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

A task list uses a ULID, like any other task.

Where the file sits is still free. The ULID is the id. It is not a kebab slug.
