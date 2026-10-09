---
type: decision
title: "Pin — file names carry the ULID and the name"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: task files and task-list files are named with the ULID and the name, not the ULID alone."
tags: [atlas-tasks, pin, task-list, filename, ulid]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-list-id-ulid.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

A task-list file name includes the ULID and the task-list name.

A task file name includes the ULID and the task name. Current atlas-tasks files that use only the ULID change to this shape.

The id stays the ULID. The name in the file is the file-safe form of the title, with the ULID first.
