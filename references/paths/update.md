# Path: update

Load `references/paths/activation.md` first. Card `path: update`.

Change an existing task or task list without the complete ritual. Completing → path **complete**. New task/list → path **add**.

## Inputs

- `atlas_id` / root (**required**)
- `task_id` (`atlas://…/ULID`), ULID, or path under a folder already reached by a pointer (**required**)
- optional patches: title, `task_status`, `body_path`, body prose, `assignees`, `parent`, `sub_tasks`, `task_list` / list `tasks`, dependency targets (`relates_to` kind dependency/blocks), other `relates_to`

## Fail closed

- Missing Atlas id/root → `incomplete: missing Atlas id`
- Unknown id after pointer walk from root (and ULID-prefix match only inside the reached folder) → stop
- Kebab id (post-v0.5 migrate) → fail closed; route to **migrate** if store still kebab
- Singular `assignee` key → reject; use `assignees` list
- Request to write `depends_on`, `display_slug` as identity, or `members` → reject
- `task_status` outside `open` | `in_progress` | `done` | `cancelled` (including `blocked` / `duplicate`) → reject
- Target is `type: task-list` and the patch includes task-only fields (`task_status`, `body_path`, `related_node`, `assignees`, `parent`, `sub_tasks`, or dependency/`blocks` `relates_to`) → reject based on target type (lists have no status lifecycle)
- Hierarchy cycle; cross-Atlas parent; unknown parent; non-task dependency target → fail closed; do not leave divergent dual-write
- List self-link or list-membership cycle (reparenting a list under itself or one of its descendants) → fail closed before any folder move or dual-write
- Divergent `task_list` vs list `tasks` pair that cannot be repaired in one write → fail closed
- Setting a **task**'s `task_list` to the root URI → reject before any move or dual-write. Loose root tasks omit the field. Root placement uses the clear-membership branch, not a write of the root URI
- Copying a target list's task URIs into a pointing list → reject
- Moving a nested task list by relocating only its `.task-list.md` file (folder and descendants left behind) → reject
- Clearing `task_list` on a task list so that it becomes a loose task → reject; reparent the whole list folder to the root
- Renaming the root index away from `tasks/index.md` → reject; title edits leave that path unchanged
- Store-wide scan to find a file → forbidden; walk from root only

## Steps

1. Require named Atlas with `tasks/` surface and URI-shaped ids (else **migrate**). Resolve the page by walking pointers from `tasks/index.md`; inside the reached folder, a stale filename may match by ULID prefix only.
2. Resolve the target's `type`. If it is `task-list`, reject any task-only patches (`task_status`, `body_path`, `related_node`, `assignees`, `parent`, `sub_tasks`, dependency/`blocks` `relates_to`) before applying anything — do not validate those enums and then apply them to a list. Apply remaining requested field patches. Never write `blocked_by`, `depends_on`, `members`, or `display_slug` as identity; never invent `task_status: blocked`. Do not change the ULID segment of `task_id`.
3. **Title / rename:** if title changes, recompute file-safe name. **Root task list:** keep path `tasks/index.md` unchanged — never rename the discovery entry point on a root title edit. **Tasks and non-root lists:** rename the file (and, for a non-root list, rename its folder and the `.task-list.md` basename) and rewrite body mentions that pointed at the old path/slug **in the same skill write**. Pointers in frontmatter stay ULID URIs (unchanged).
4. **Dual-write hierarchy sync** (tasks only): same as v0.5 — parent/`sub_tasks` both ends; same-Atlas; no cycles.
5. **Dual-write membership sync.** Task-file moves and whole-list-folder moves are different. A nested task list is never relocated by moving only its list file, and clearing its `task_list` does not make it loose.
   - **Task — set or change `task_list`:** the new value must be a **non-root** list. If the value is the root URI, **reject it before any move or dual-write** — do not write the root URI into the task. Root placement is only the clear-membership branch (omit `task_list`). Otherwise remove the task URI from the previous list's `tasks` and body mention; append it to the new list's `tasks` and body mention; **move that task file** into the new list folder; clear any loose root row for that URI.
   - **Task — clear `task_list` (become loose):** remove the URI from the child list; **move the task file** beside `tasks/index.md`; append the URI to the root `tasks` and body mention; omit `task_list`. Only a task may be loose.
   - **Nested task list — reparent:** Fail closed first if the new parent is this list or any descendant of this list (self-link / membership cycle) — do not move folders or dual-write when that would cycle. Then move the **whole list folder** (the list file, its folder, and every descendant) into the new parent list's folder. Do not move the `.task-list.md` alone — that leaves the folder and descendants behind. Remove the list URI from the previous parent's `tasks` and body mention; append it to the new parent's `tasks` and body mention; set this list's `task_list` to the new parent URI. Do not copy descendant task URIs onto the new parent.
   - **Nested task list — clear `task_list`:** do **not** omit `task_list` and do **not** treat the list as a loose task. Reparent it to the **root** task list in one write: remove the list URI from the former parent's `tasks` and body mention; move the whole list folder under `tasks/`; set `task_list` to the root list URI; append the list URI to the root `tasks` and body mention.
   - Editing a list's `tasks`: for each added or removed URI, update that member in the same write. A **task** member added to a **non-root** list gets its `task_list` set to that list and its **file** moved as above. A **task** member placed on the **root** (added to the root `tasks`, or given the root URI) does **not** store the root URI: reject a root-URI `task_list` value before any mutation, and use the clear-membership branch so the task omits `task_list`, moves beside `tasks/index.md`, and is listed on the root. A **task-list** member gets its `task_list` set to this list (append here; remove from its former parent's `tasks` and body mention), or — when it is removed from a non-root list — reparented to the root: remove its URI from this list's `tasks` and body mention, set `task_list` to the root, append to the root `tasks` and body mention, and move its **whole folder** — but only after the same list-cycle check (adding this list under itself or a descendant fails closed before any move). List-to-list adds are a pointer only — do not copy nested members.
6. **Dual-write dependency sync:** unchanged from v0.5 (task targets only).
7. Recompute derived blocked on next **list** / index refresh.
8. **Duplicate:** prefer `task_status: cancelled` plus `relates_to` the surviving task — not a fifth status.
9. Compile green.
