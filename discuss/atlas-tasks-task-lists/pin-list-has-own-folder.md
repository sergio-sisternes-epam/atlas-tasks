---
type: decision
title: "Pin — a task list has its own folder"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: a task list is a folder that groups the tasks in that cluster."
tags: [atlas-tasks, pin, task-list, folder]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-list-lives-anywhere.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-filename-ulid-and-name.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

A task list has its own folder. The tasks in that logical cluster live in that folder.

The folder name carries the ULID and the task-list name, the same way a task file does.
