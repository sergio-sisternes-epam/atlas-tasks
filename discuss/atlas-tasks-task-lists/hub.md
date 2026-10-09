---
type: experience
title: "Hub — atlas-tasks task lists"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: in-discussion
kva: alive
reality: current
description: "discussion_root. A grouping such as a release plan gets its own task-list file, linked from the main index, with membership visible in frontmatter and in the list."
tags: [atlas-tasks, discuss, task-list, index]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
  - path: discuss/atlas-tasks-task-lists/current-reality.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-task-list-own-file.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-main-index-is-a-task-list.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-membership-both-sides.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-list-link-is-a-pointer.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-membership-field-names.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-list-lives-anywhere.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-navigation-frontmatter-and-mention.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-list-id-ulid.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-filename-ulid-and-name.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-list-has-own-folder.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/pin-task-list-extension.md
    kind: follows
  - path: discuss/atlas-tasks-task-lists/protostar-list-vs-parent.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/protostar-index-shows-members.md
    kind: follows
  - path: autogenesis/plans/2026-10-04-atlas-tasks-task-lists.md
    kind: related
---

## Context

Subject: atlas-tasks task lists.

Objective: tasks grouped for one purpose (for example, preparing a release) live in their own task-list file, following atlas-tasks discipline, while the main task list keeps a link. Frontmatter and the task list are both aware of those lists.

## Where this sits

v0.5 already has one `tasks/index.md` per Atlas, and parent plus child links for hierarchy. This orbit does not reopen task identity. It asks for a list that is a grouping, not a new identity scheme.

Pinned 2026-10-04: any task list has its own file, linked from the main index. A parent task is not a list.

Pinned 2026-10-04: the main index is itself a task list. It holds other lists and loose tasks.

Pinned 2026-10-04: a task names its list, or none if loose. A list names its tasks.

Pinned 2026-10-04: a list points at another list and does not copy its tasks. Fields are `task_list` on the task and `tasks` on the list.

Pinned 2026-10-04: a task list may live anywhere in the Atlas. The root task list is the only entrypoint.

Pinned 2026-10-04: navigation is the frontmatter link plus a mention in the task list.

Pinned 2026-10-04: a task list id is a ULID, like a task.

Pinned 2026-10-04: task files and task-list files are named with the ULID and the name.

Pinned 2026-10-04: a task list has its own folder, and the tasks in that cluster live there.

Pinned 2026-10-04: a task-list file ends in `.task-list.md`. The type is the contract and the extension is the check.
