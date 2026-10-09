---
type: document
title: "Current reality — task lists are membership, not parents"
created: "2026-10-04"
updated: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
status: in-discussion
kva: alive
reality: current
description: "Pinned: list folders, ULID-plus-name files, main index as a list, and both sides name the membership."
tags: [atlas-tasks, living-thesis, task-list]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
  - path: discuss/atlas-tasks-task-lists/pin-task-list-own-file.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-main-index-is-a-task-list.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-membership-both-sides.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-list-link-is-a-pointer.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-membership-field-names.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-list-lives-anywhere.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-navigation-frontmatter-and-mention.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-list-id-ulid.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-filename-ulid-and-name.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-list-has-own-folder.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/pin-task-list-extension.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/protostar-list-vs-parent.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/protostar-index-shows-members.md
    kind: related
  - path: autogenesis/plans/2026-10-04-atlas-tasks-task-lists.md
    kind: related
---

## Living thesis

Pinned 2026-10-04: any task list has its own file. A parent task with children is not a task list.

Pinned the same day: `tasks/index.md` is itself a task list. It holds other task lists and loose tasks that belong to no specific list. A task inside a specific list stays in that file. It is not also a loose row on the main index.

Pinned the same day: a task names its list, or none if it is loose. A list names its tasks. The main index, being a list, names the lists and loose tasks it holds.

Pinned the same day: a link from one list to another is only a pointer. Tasks are not copied. The task field is `task_list` (omit when loose). The list field is `tasks`, each a pointer to a task or a list.

Pinned the same day: a task-list file may live anywhere in the Atlas. The root task list is the only entrypoint. Pinned the same day: a task list id is a ULID, like a task.

Pinned the same day: a task file and a task-list file are named with the ULID and the name. The id stays the ULID.

Pinned the same day: a task list has its own folder. The tasks in that cluster live in that folder.

Pinned the same day: the list file ends in `.task-list.md`. `type: task-list` is the contract. The extension is the check.

Pinned the same day: navigation is the frontmatter link and a mention in the task list.
