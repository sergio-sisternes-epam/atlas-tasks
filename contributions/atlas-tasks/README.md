# atlas-tasks contribution

## What this overlay does

- Claims the `tasks/` folder on the target Atlas (`tasks/index.md` lives here as the root task list).
- Adds overlay type **`task-list`** (new type — not a core redeclaration).
- Leaves core Atlas `task` in place. The discipline **extends** it through skill-enforced frontmatter (see below), not through SCHEMA.

## Overlay contents and extension contract

`SCHEMA.overlay.json` carries **only Atlas contract keys**. Today it sets `contribution_id`, `claimed_folders` and `templates`; the allowed set is `contribution_id`, `claimed_folders`, `templates`, `types`, `bindings`, `presets`. It has no package metadata key. Up to v0.6.1 the overlay also shipped an informational `atlas_tasks` root object (`atlas_todo` in v0.2.0). Nothing read it, and Atlas SCHEMA 2.0 stores (Atlas 0.10.0 to 0.13.0) reject unknown overlay root keys at `schema install`, so v0.6.2 removed it.

This README is the **normative extension contract**:

- **Extended core type:** `task`. Atlas SCHEMA rejects an overlay that redeclares core `templates.by_type.task` (`overlay_core_type`), so the overlay leaves `task` alone and adds only the new type `task-list`.
- **Extension mode:** skill-enforced frontmatter. The skill enforces the fields in the task and task-list contract tables below; Atlas SCHEMA does not. Blocked is derived from `kind: dependency` edges and never stored. Hierarchy (`parent` / `sub_tasks`) is same-Atlas only; dependency edges may cross Atlases through `atlas://` URIs and resolve fail-closed.
- **Version cuts:** v0.3 hard cut from `todo/` to `tasks/` (no read shim); v0.4 no `depends_on`; v0.5 `task_id` is `atlas://<atlas_id>/tasks/<ULID>` (no kebab `task_id` or `display_slug`); v0.6 ULID-plus-name filenames and task lists; v0.6.2 the overlay carries Atlas contract keys only (no page, frontmatter or schema-key change).

## What it does not do

- It does **not** redeclare `templates.by_type.task` (Atlas compile fails with `overlay_core_type`).
- It does **not** introduce a rival primary task type.
- It does **not** store `blocked_by` as a field, nor `task_status: blocked`.
- It does **not** store `depends_on` (removed in v0.4.0 — use `relates_to` dependency/blocks).
- It does **not** read legacy `todo/`, `todo_id`, or `todo_status` (hard cut at v0.3.0 — migrate first).
- It does **not** accept kebab `task_id` or invent a `display_slug` as identity (hard cut at v0.5.0 — migrate first).
- It does **not** treat a parent task as a list, use `members` as the list field, or copy tasks when linking lists.

## Task extension contract (skill-enforced)

When a page is an atlas-tasks pointer, keep `type: task` and set:

| Field | Required | Meaning |
|---|---|---|
| `task_id` | yes | Full `atlas://<atlas_id>/tasks/<ULID>` composite |
| `task_status` | yes | `open` \| `in_progress` \| `done` \| `cancelled` |
| `body_path` | yes | Store-relative path to colocated task body |
| `related_node` | recommended | Store-relative path of the knowledge node this task sits beside |
| `assignees` | optional | YAML list of human handles or agent path-slugs; self allowed. **Never** singular `assignee` |
| `parent` | optional | At most one same-Atlas parent `atlas://…/ULID` |
| `sub_tasks` | optional | YAML list of child `atlas://…/ULID` values (maintained by dual-write) |
| `task_list` | optional | URI of the owning **non-root** task list; **omit when loose** (loose tasks appear only on the root index — never store the root URI) |
| `relates_to` | optional | Atlas edges. Dependency: waiter `{ path: <blocker atlas:// or pointer>, kind: dependency }`; same-Atlas blocker dual-write `{ path: <waiter>, kind: blocks }`. Other kinds (e.g. duplicate → surviving) allowed. **Never** `depends_on` |

Pointer file path: `tasks/<ULID>-<file-safe-name>.md` when loose, or `<list-folder>/<ULID>-<file-safe-name>.md` when in a list cluster. Never `.task-list.md` for tasks.

## Task-list contract (skill-enforced)

| Field | Required | Meaning |
|---|---|---|
| `type` | yes | `task-list` |
| `task_id` | yes | Full `atlas://<atlas_id>/tasks/<ULID>` (same URI grammar as tasks) |
| `tasks` | recommended | YAML list of member URIs (tasks or other lists). **Not** `members`. **Not** `parent` / `sub_tasks` |
| `task_list` | optional | URI of the parent list when this list is nested; **root index always omits** `task_list` (never a self-reference) |

Root path: `tasks/index.md` — reserved name; sole suffix exception (does not end in `.task-list.md`).

Non-root path: `<parent>/<LIST_ULID>-<file-safe-name>/<LIST_ULID>-<file-safe-name>.task-list.md` with a matching folder. Default parent folder is the folder of the list that points at it (root folder is `tasks/`).

Body must **mention** each `tasks` entry (navigation = frontmatter + mention). List-to-list entries are pointers only — do not copy the target list's task URIs into this list's `tasks`.

## Derived blocked / dual-write (unchanged from v0.5)

**Derived blocked (not a field):** a pointer is treated as blocked for list/index when any of its `relates_to` edges with `kind: dependency` targets a pointer whose `task_status` is still non-terminal (`open` or `in_progress`). Terminal targets (`done` / `cancelled`) clear that block. Unknown/unmounted/unreadable **remote** targets fail closed. Do not write `task_status: blocked` or a stored `blocked` boolean.

**Dependency dual-write (same-Atlas):** when a waiter gains `kind: dependency` → blocker, the blocker must gain `kind: blocks` → waiter (and vice versa on clear). Cycles forbidden. Targets remain `type: task` — reject bodies, shops, quotes, task lists.

**Cross-Atlas dependency:** waiter may store remote `atlas://…/ULID`. This cut does **not** write `kind: blocks` on the foreign Atlas.

**Hierarchy dual-write:** when `parent` is set on a child, the parent’s `sub_tasks` must include that child (and vice versa). **Same-Atlas only.** A parent with children is not a task list.

**Membership dual-write (v0.6):** one skill write updates the task's `task_list` and the list's `tasks` together. Pointer key is the ULID URI. Compliance walks from `tasks/index.md` and fails if the two sides disagree, if a child-list member also appears as a loose root row, or if a list-to-list entry duplicated the target's task URIs.

**Rename (v0.6):** title change → new file-safe name → rename file (and list folder when applicable) and rewrite body mentions in the same write. The root list keeps `tasks/index.md` — title edits never rename the root file. Identity (`task_id` URI / ULID) does not change. No store-wide scan; ULID-prefix match only inside a folder already reached by a pointer.

**Human-facing:** title + ULID only. File-safe slug is not identity.

## Install

```bash
python3 <atlas-skill>/scripts/atlas.py schema install \
  <this-package>/contributions/atlas-tasks \
  --root <user-named-atlas-root>
python3 <atlas-skill>/scripts/atlas.py compile --root <user-named-atlas-root>
```

Only mount on an Atlas the user named.

The overlay installs on both SCHEMA 1.0 and SCHEMA 2.0 stores. If a store holds the v0.6.1 (or older) overlay, rerun the same `schema install` with v0.6.2. `--force` is not needed. Do this **before** any `schema upgrade --to 2.0`: a store that still holds the old overlay can report the upgrade as ok and then fail compile.

## Migrate

### From atlas-todo / `todo/` (v0.2 → v0.3)

Hard cut — no shim. See skill path **migrate** Checklist A.

### From `depends_on` (v0.3 → v0.4)

See Checklist B.

### From kebab `task_id` (≤ v0.4 → v0.5)

Hard cut — no dual-read. See Checklist C.

### From ULID-only filenames / document index (v0.5 → v0.6)

1. For each `type: task` pointer still at `tasks/<ULID>.md`, rename to `tasks/<ULID>-<file-safe-name>.md` (derive name from `title`). Preserve ULID / `task_id`.
2. Convert `tasks/index.md` to `type: task-list` with a minted root `task_id` and `tasks:` listing every loose task URI (and any existing list URIs). Body mentions each member. The root **omits** `task_list` (never self-reference). When minting the root ULID, compare it with all inventoried IDs (every task URI from step 1 and any other IDs already inventoried) and remint once before accepting it; if the remint still collides, stop.
3. For each new task list: create folder `<ULID>-<name>/` and list file `<ULID>-<name>.task-list.md`. Dual-write the new list's parent edge (root by default) before removing member URIs from the root: set the new list's `task_list` to the parent URI (the root page itself still omits `task_list`), append the new list URI to the parent's `tasks`, and mention the list in the parent body. Then move member tasks into that folder, set each member's `task_list`, dual-write the new list's `tasks` and body mentions, and remove those URIs from the root loose `tasks` rows.
4. Compile green. After migrate, skill writes only ULID-plus-name paths; do not invent ULID-only filenames.
