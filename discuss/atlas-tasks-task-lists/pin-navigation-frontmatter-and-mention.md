---
type: decision
title: "Pin — navigation is a frontmatter link and a mention in the list"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: accepted
kva: alive
reality: current
description: "Living pin: membership is in frontmatter, and the task list also mentions the link so navigation is readable."
tags: [atlas-tasks, pin, task-list, navigation]
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

Navigation is not frontmatter alone.

The frontmatter link stays as pinned: `task_list` on the task, `tasks` on the list, each a pointer.

The task list also mentions that link in the list itself, so a reader can follow it without reading only the frontmatter.
