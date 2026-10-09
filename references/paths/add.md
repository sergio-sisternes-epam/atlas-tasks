# Path: add

**Create a new task or a new task list.** Do not use this path to mark an existing task done — that is path **complete**.

## Activation

Load `references/paths/activation.md` first. Card `path: add`.

## Inputs

- `atlas_id` / root (**required**)
- `title` (**required**)
- for a **task**: `related_node` store-relative path (**required** for colocation)
- optional body prose
- optional `task_id` — must already be a well-formed `atlas://<this-atlas_id>/tasks/<ULID>`; if missing, **mint** a ULID and build that URI (never mint a kebab slug)
- optional `assignees: []` (human handles or agent path-slugs; never singular `assignee`)
- optional `parent` (one same-Atlas `atlas://…/ULID`) — hierarchy only; does **not** make this a list
- optional `task_list` — URI of an existing **non-root** task list to join. The root is a task list, but it is not a legal value: for a **loose** task on the root index, omit `task_list` (do not set it to the root URI)
- optional dependency targets: same-Atlas or cross-Atlas task ids (`atlas://…/ULID`) or same-Atlas pointer paths → stored as `relates_to` `kind: dependency`
- optional `task_status` (default `open`; allowed: `open` | `in_progress` | `done` | `cancelled`)
- optional `kind: task-list` (or user asks for a “list” / “task list”) — create a task-list page instead of a task

## Fail closed

- Missing Atlas id/root → `incomplete: missing Atlas id`
- User said “complete / done / finish” an existing task → switch to path **complete** (do not add a duplicate)
- Singular `assignee` key requested → reject; use `assignees` list
- Request to write `depends_on` → reject; use dependency `relates_to` edges (or **migrate** first)
- Kebab `task_id` or request for `display_slug` as identity → reject; mint ULID / use `atlas://` (or **migrate**)
- Unknown parent, task_list, or dependency target → stop
- `task_list` set to the root task-list URI → reject before writing; root placement omits the field
- Parent on another Atlas → fail closed
- Dependency target that is not a `type: task` pointer / task id (body, shop, quote, task-list) → fail closed
- Hierarchy or dependency cycle → fail closed; write nothing divergent
- Request to use `members` as the list field, or to copy tasks into a pointing list → reject
- Legacy `todo/` without `tasks/` or unmigrated kebab / ULID-only stores when migrate is required → stop; route to **migrate**

## Steps — new task

1. Ensure overlay `atlas-tasks` is installed and `tasks/index.md` exists as `type: task-list` (else **mount-overlay** / **migrate** first or stop).
2. Resolve `atlas_id` from the named store SCHEMA. If `task_id` is supplied, validate it is a well-formed same-Atlas `atlas://<atlas_id>/tasks/<ULID>` and preserve it; otherwise mint a ULID and set `task_id = atlas://<atlas_id>/tasks/<ULID>`. Derive `file-safe-name` from title. Before accepting the ULID, walk the reachable graph from the root and compare IDs — a collision is Atlas-wide, not limited to the target folder. If a **caller-supplied** `task_id` is already reachable, fail closed as an attempted duplicate (do **not** remint or replace the requested identity). If an **internally minted** ULID is already reachable, remint once, then fail closed.
3. Write colocated **body** beside `related_node` (e.g. `task-<short>.md` in the same folder — body filename is not the task id). Full prose lives only here. Prose may say “blocked by …” but do **not** store a `blocked_by` field.
4. Choose placement:
   - **Loose (root):** file at `tasks/<ULID>-<file-safe-name>.md`; omit `task_list` (never write the root URI); append URI to root index `tasks` and mention in root body.
   - **In a non-root list:** resolve list L by walking pointers from the root (no store-wide scan). L must be an existing task list and must **not** be the root. File at `<L-folder>/<ULID>-<file-safe-name>.md`; set `task_list: <L URI>`; append URI to L's `tasks` and mention in L's body; do **not** also add a loose root row. If the caller passed the root URI, reject it and do not write.
5. Write **task pointer**:

```yaml
type: task
title: "<title>"
created: "<YYYY-MM-DD>"
task_id: "atlas://<atlas_id>/tasks/<ULID>"
task_status: open
body_path: "<store-relative body path>"
related_node: "<related_node>"
assignees: []
parent: null
sub_tasks: []
# task_list: "atlas://<atlas_id>/tasks/<LIST_ULID>"   # omit when loose
relates_to: []
```

Never write `todo_id`, `todo_status`, `depends_on`, `display_slug`, or `members`.

6. **Dual-write hierarchy:** if `parent` is set, validate same-Atlas `atlas://`; append this `task_id` to the parent’s `sub_tasks`. Reject cycles and cross-Atlas parents before writing.
7. **Dual-write membership:** if `task_list` is set, it must name a **non-root** list — reject the root URI before any write (root placement omits the field). Update that list's `tasks` and body mention in the **same write**. If clearing membership to loose, remove from the list and add to the root (and vice versa) — never leave both a child-list row and a loose root row for the same URI, and never store the root URI in `task_list`.
8. **Dual-write dependency:** for each dependency target, resolve to a task id / pointer; validate `type: task`. On this waiter append `{ path: <blocker>, kind: dependency }`. For **same-Atlas** blockers append `{ path: <this>, kind: blocks }`. For **cross-Atlas** blockers: write the local waiter edge only. Reject cycles and non-task targets before writing.
9. `atlas compile --root <root>`. Fix red before claiming success.
10. Report: `task_id` (full URI), ULID, title, body path, task path (`…/<ULID>-<name>.md`), list membership, derived blocked (yes/no).

## Steps — new task list

1. If `task_id` is supplied, validate it is a well-formed same-Atlas `atlas://<atlas_id>/tasks/<ULID>` and preserve it; otherwise mint a ULID and set `task_id = atlas://<atlas_id>/tasks/<ULID>`. Before accepting the ULID, walk the reachable graph from the root and compare IDs (Atlas-wide; another list folder counts). If a **caller-supplied** `task_id` is already reachable, fail closed as an attempted duplicate (do **not** remint or replace the requested identity). If an **internally minted** ULID is already reachable, remint once, then fail closed. Derive file-safe name from title.
2. Resolve parent list P (default: root). Walk pointers from root to find P's folder (root folder is `tasks/`).
3. Create folder `<P-folder>/<ULID>-<file-safe-name>/` and list file `<ULID>-<file-safe-name>.task-list.md` inside it:

```yaml
type: task-list
title: "<title>"
created: "<YYYY-MM-DD>"
task_id: "atlas://<atlas_id>/tasks/<ULID>"
task_list: "atlas://<atlas_id>/tasks/<PARENT_LIST_ULID>"
tasks: []
```

4. Body section listing members (empty at create). When members are added later, each `tasks` URI must appear as a body mention.
5. Dual-write: append this list URI to P's `tasks` and mention it in P's body. Do **not** copy any of this list's future members into P.
6. Compile green. Report list URI, folder path, and parent list.

## Root index contract (`tasks/index.md`)

```yaml
type: task-list
title: Tasks index
created: "<YYYY-MM-DD>"
task_id: "atlas://<atlas_id>/tasks/<ROOT_ULID>"
# task_list: omitted — the root never sets task_list (no self-reference, no parent)
tasks:
  - atlas://<atlas_id>/tasks/<LIST_OR_LOOSE_ULID>
```

Body mentions each `tasks` entry. Columns/tables in the body are optional display; frontmatter `tasks` is authoritative with the body mentions. A URI listed inside a child list must not also appear as a loose root `tasks` entry. The root index **always omits** `task_list` — never a self-reference to its own `task_id`.

## Non-goals

- Completing or cancelling an existing task
- Writing a foreign Atlas (including remote `blocks`)
- Storing `blocked_by`, `depends_on`, `display_slug`, `members`, or `task_status: blocked`
- Accepting `todo_id` / `todo_status` or kebab `task_id` keys
- Treating parent/`sub_tasks` as list membership
