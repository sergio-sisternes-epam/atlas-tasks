---
type: decision
title: "Pin — a task list file ends in .task-list.md"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: the list file uses .task-list.md; type task-list is the contract and the extension is the check."
tags: [atlas-tasks, pin, task-list, extension]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/pin-list-has-own-folder.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
---

## Decision

A task-list file ends in `.task-list.md`. A task file stays `.md`.

The contract is frontmatter `type: task-list`. Compliance checks that a file with that type ends in `.task-list.md`, and that a task file does not.
