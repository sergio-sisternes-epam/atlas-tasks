# Path: complete

**Mark an existing task done.** Do not create a new task here — that is path **add**.

## Activation

Load `references/paths/activation.md` first. Card `path: complete`.

## Inputs

- `atlas_id` / root (**required**)
- `task_id` (`atlas://…/ULID`), ULID, or path under a folder reached by a pointer (**required**)

## Fail closed

- Missing Atlas id/root → `incomplete: missing Atlas id`
- Unknown id after pointer walk → stop; do not invent a new task via **add** unless the user explicitly asks to add one
- Kebab id after v0.5 migrate → fail closed
- Target is a `type: task-list` → stop; lists are not completed via this path
- User asked to “add a new task/todo” → switch to path **add**
- Legacy `todo/` only or unmigrated kebab store → route to **migrate**

## Steps

1. Resolve the task pointer by walking from `tasks/index.md` (ULID-prefix match only inside the reached folder).
2. Set `task_status: done` on the pointer. Keep `body_path`, `related_node`, `assignees`, `parent`, `sub_tasks`, `task_list`, and `relates_to`.
3. Refresh display rows on the owning list / root if maintained as a table; recompute derived blocked for waiters that depended on this task when refreshing.
4. Compile green.
5. Do **not** delete body or pointer unless the user asked to cancel/remove (use **update** for `cancelled`, including duplicate → `cancelled` + `relates_to`).

## Non-goals

- Creating a new task or task list
- Dumping body prose into the index
- Setting `task_status: blocked`
- Writing `depends_on`, `display_slug`, or `members`
