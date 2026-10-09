# Path: migrate

Upgrade consumer Atlases for atlas-tasks. Covers:

1. **v0.2 → v0.3:** atlas-todo (`todo/`, `todo_id`, `todo_status`) → atlas-tasks (`tasks/`, `task_id`, `task_status`). **No read shim.**
2. **v0.3 → v0.4:** `depends_on: […]` lists → `relates_to` `kind: dependency` / `kind: blocks` edges; drop `depends_on`.
3. **≤ v0.4 → v0.5:** kebab `task_id` → `atlas://<atlas_id>/tasks/<ULID>`; flatten pointers to `tasks/<ULID>.md` shape first if needed. **No dual-read.**
4. **v0.5 → v0.6:** ULID-only filenames → `<ULID>-<file-safe-name>`; root `tasks/index.md` → `type: task-list`; optional list folders + membership dual-write. Install the v0.6 overlay before this step converts the root (see Checklist D).

## Activation

Load `references/paths/activation.md` first. Card `path: migrate`.

## Inputs

- `atlas_id` / root (**required** to apply; optional for explain-only)
- confirmation that the operator accepts breaking one-shot renames / edge migration

## Checklist A — todo/ → tasks/ (v0.2 → v0.3)

1. Retarget the package install pin to `atlas-tasks` (after publish: `sergio-sisternes-epam/atlas-tasks#v0.6.3`).
2. On the named Atlas root, rename the overlay folder: `todo/` → `tasks/`.
3. For every pointer page under `tasks/`, rewrite frontmatter: `todo_id` → `task_id`, `todo_status` → `task_status`.
4. Rewrite `tasks/index.md`; drop `todo_` column headers.
5. Remove leftover `todo/`; fail closed if `todo/` remains without a migrated `tasks/`.
6. Install contribution `atlas-tasks` (claims `tasks/`); compile green.
7. Continue with Checklist B / C / D as needed.

## Checklist B — depends_on → dependency/blocks (v0.3 → v0.4)

1. Inventory every `type: task` pointer that still has `depends_on`.
2. Convert each entry to waiter `kind: dependency` + same-Atlas blocker `kind: blocks`; drop `depends_on`.
3. Reject cycles; compile green.

## Checklist C — kebab → atlas://…/ULID (≤ v0.4 → v0.5)

1. Read `atlas_id` from the store SCHEMA.
2. Inventory every `type: task` pointer under `tasks/` (including nested `tasks/tasks/<kebab>.md`).
3. For each pointer whose `task_id` is **not** already `atlas://<atlas_id>/tasks/<26-char-ULID>`: mint or preserve ULID; set URI; move to a ULID-based filename (temporary ULID-only is acceptable mid-migrate before Checklist D).
4. Rewrite `parent`, `sub_tasks`, and `relates_to` through the map.
5. Compile green. **After migrate:** fail closed on kebab `task_id` inputs (**no dual-read**).

## Checklist D — ULID-only → ULID-plus-name + root task list (v0.5 → v0.6)

Prerequisite: the v0.6 `atlas-tasks` overlay is already installed, so `type: task-list` is in the schema. If it is not, stop and run **mount-overlay** (v0.5 stores) or finish the Checklist A contribution install (older stores) first. Do not convert the root against the old overlay.

1. For each `type: task` at `tasks/<ULID>.md` (or any ULID-only basename), rename to `tasks/<ULID>-<file-safe-name>.md` from `title`. Preserve `task_id`.
2. Ensure `tasks/index.md` is `type: task-list` with a root `task_id` (mint if missing) and `tasks:` listing every **loose** task URI. Body mentions each entry. Do not list URIs that will live only inside child lists. When minting the root ULID, compare it with all inventoried IDs (every task URI from step 1 and any other IDs already inventoried) and remint once before accepting it; if the remint still collides, stop.
3. For each task list to create: folder `<ULID>-<name>/`, file `<ULID>-<name>.task-list.md`. Dual-write the new list's parent edge (root by default) before removing member URIs from the root: set the new list's `task_list` to the parent URI (the root `task_id` unless a nearer parent list was requested; the root page itself still omits `task_list`), append the new list URI to the parent's `tasks`, and mention the list in the parent body. Then move members into the folder, set each member's `task_list` to the new list, dual-write the new list's `tasks` + body mentions, and remove those member URIs from the root loose `tasks`. An unlinked list is unreachable under root-only discovery.
4. List-to-list: pointer only — do not copy nested task URIs.
5. Compile green. After migrate, skill writes only ULID-plus-name paths; discovery is pointer walk from root only.

## Fail closed

- Missing Atlas id when applying → `incomplete: missing Atlas id`
- `todo/` present and `tasks/` absent after attempted rename → do not claim success
- Unknown / non-pointer dependency target during Checklist B → stop
- Collision on minted ULID that survives one remint → stop
- Skill must not treat unmigrated `todo_id` / `todo_status`, `depends_on`, or kebab `task_id` as valid contract keys after migrate
- Do not leave a child-list member also as a loose root row
- New list missing its parent edge (list `task_list` + parent `tasks` and body mention; root by default) before member URIs leave the root → stop

## Non-goals

- Keeping dual-path reads for `todo/`
- Keeping `depends_on` as a derived cache field
- Dual-read / alias map for kebab ids
- Writing foreign Atlases during migrate
- Store-wide discovery of lists without root pointers
