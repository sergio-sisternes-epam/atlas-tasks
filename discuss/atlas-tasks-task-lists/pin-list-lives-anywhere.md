---
type: decision
title: "Pin — task lists live anywhere; the root list is the entrypoint"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: a task-list file may sit anywhere in the Atlas. The only entrypoint is the root task list."
tags: [atlas-tasks, pin, task-list, path]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-membership-field-names.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

A task-list file may live anywhere in the Atlas. There is no required folder.

The entrypoint is always the root task list. Other lists are found by following pointers from that root, not by scanning the store for list files.

The id shape of a list file is not part of this pin.
