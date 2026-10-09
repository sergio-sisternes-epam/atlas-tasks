---
name: atlas-tasks
description: Use for distributed Atlas tasks — add/update/complete tasks and task lists, maintain per-Atlas tasks/index.md as the root task list, mount the atlas-tasks overlay on a user-named Atlas, and list/recall task pointers with assignees, hierarchy, task_list membership, relates_to dependency/blocks dual-write and derived blocked. Trigger on atlas-tasks, atlas-todo, tasks index, todo index, add task, add todo, complete task, list tasks, recall tasks, query tasks (deprecated alias of recall), task list, task-list, mount tasks overlay, distributed task, assignees, sub-tasks, depends_on, dependency, blocks, atlas://, ULID. Builds on core Atlas task; does not replace Governor tasks or APM HITL queues.
metadata:
  version: "0.6.3"
  status: mvp
  work_id: 2026-10-04-atlas-tasks-task-lists
---

# atlas-tasks

Distributed Atlas **task** discipline. Each participating Atlas has `tasks/index.md` as the **root task list**. Task **bodies** live colocated next to related knowledge nodes. Core Atlas **`task`** pages and task-list pages act as **pointers**. Agents coordinate across Atlases by reading indexes on Atlases the user named.

**v0.6.0** — breaking filename shape + new task-list surface: `type: task-list` (own file, own folder); root `tasks/index.md` is the list of lists and loose tasks; membership via `task_list` / `tasks` pointers (ULID URIs); filenames `<ULID>-<file-safe-name>` (`.task-list.md` for non-root lists). `task_id` stays `atlas://<atlas_id>/tasks/<ULID>` with no slug in the URI. Parent/`sub_tasks` stay; a parent is not a list. Discovery walks pointers from the root only. Package identity remains `atlas-tasks`.

**v0.6.2** — the overlay carries only Atlas contract keys, so it installs on SCHEMA 2.0 stores. No page, frontmatter or schema-key change. Reinstall with `schema install` (no `--force`) before any `schema upgrade --to 2.0`.

**v0.6.3** — the read verb is now **recall**, Atlas core's verb; **query** remains a deprecated alias routing to **list**. No page, frontmatter or schema-key change.

## Pins (normative)

1. **Distributed:** every Atlas using this discipline has `tasks/index.md`; tasks may be local or remote; agents coordinate across Atlases.
2. **Entity:** this skill + overlay; overlay extends core `task` (skill-enforced fields; SCHEMA cannot redeclare core `task`) and may declare `task-list` as an overlay type.
3. **vs Governor/HITL:** build on `task`; complement, do not wholesale replace.
4. **Packaging:** install this APM package; mount overlay only on the Atlas the user indicates.
5. **Colocation:** bodies beside related nodes; `task` + index / task-list pages are pointers.
6. **Ownership:** `assignees: []` — list of human handles or agent path-slugs; self allowed. Never singular `assignee`.
7. **Hierarchy:** dual-write `parent` (at most one) + `sub_tasks` on the parent; skill keeps both ends in sync; cycles forbidden; **same-Atlas only** (values are `atlas://…/ULID` ids on this store). A parent with children is **not** a task list.
8. **Dependency:** waiter stores `relates_to: [{ path: <task-id-or-pointer>, kind: dependency }]`; same-Atlas blocker dual-writes `relates_to: [{ path: <waiter>, kind: blocks }]`. Skill syncs both ends on add/update/clear **inside one Atlas**. **Cross-Atlas** dependency targets use `atlas://…/ULID`; write the local waiter edge; do **not** write a remote `kind: blocks` until the reverse-edge pin locks (open protostar). **No `depends_on` field**. Cycles forbidden on the resolvable graph. `blocked_by` is prose-only, not a stored field.
9. **Blocked:** derived when any waiter `kind: dependency` target has `task_status` ∈ {`open`,`in_progress`}; `done`/`cancelled` clear; empty dependency set → not blocked. **Fail-closed remote:** unknown, unmounted, or unreadable remote target → treat as unresolved / blocked (or path error) — never “ok because missing”. No `task_status: blocked`; no separate boolean.
10. **Status:** `task_status` is `open` | `in_progress` | `done` | `cancelled`. Duplicate = `cancelled` + `relates_to` the surviving task (not a fifth status). Task lists do not use `task_status` for membership.
11. **Identity (v0.5+):** `task_id` **is** `atlas://<atlas_id>/tasks/<ULID>` for tasks **and** task lists → physical file named `<ULID>-<file-safe-name>` (see pin 16). `<atlas_id>` is the scheme-free canonical Atlas id; `<ULID>` is 26-character Crockford. No fragment/query. No kebab `task_id`. No kebab `display_slug`. No slug in the URI.
12. **Human-facing:** show **title + ULID** (final path segment of the URI). Full `atlas://` URI is fine for tracing; do not invent a kebab stand-in. The file-safe name after the ULID is readable storage only — not the id.
13. **Hard cut (v0.3):** require `tasks/` + `task_id` / `task_status` only; do not read `todo/`, `todo_id`, or `todo_status`.
14. **Hard cut (v0.5):** do not accept, resolve, or shim kebab `task_id`s after migrate — unknown kebab → fail closed.
15. **Dependency targets:** `kind: dependency` / `kind: blocks` target `type: task` pointers / task ids only (not bodies, shops, quotes, or task lists). Same-Atlas or cross-Atlas via `atlas://`; fail closed otherwise.
16. **Filename (v0.6):** task and task-list basenames are `<ULID>-<file-safe-name>` — ULID first, hyphen, then a file-safe form of the title/name. ULID-only filenames are no longer the shape this skill writes. Id remains the ULID. A title change **renames the file** and **rewrites body mentions** in the **same skill write**, except the **root task list** keeps the reserved path `tasks/index.md` — title edits never rename the root index (pin 21).
17. **Task list (v0.6):** a page with `type: task-list`, its own file, and (for non-root) its own folder. Not a parent task. Fields: list `tasks` (pointers to task or list URIs — never `members`); task `task_list` (omit when loose). List-to-list is a pointer only — do not copy member tasks into the pointing list.
18. **Root index (v0.6):** `tasks/index.md` is the root task list. It holds other lists and loose tasks. A task that belongs to a specific child list is **not** also a loose row on that index.
19. **Navigation (v0.6):** membership is the frontmatter pointer **and** a mention of that same member in the task-list body.
20. **Placement / discovery (v0.6):** non-root list folder is named `<ULID>-<file-safe-name>`; member tasks live in that folder; loose tasks live beside `tasks/index.md`. Where a list folder sits is found only by following pointers from the root. **No store-wide scan** to discover lists or tasks. The compliance walk that starts from the root is required and is **not** a discovery scan for agents. Inside a folder already reached by a pointer, a stale filename may match by ULID prefix only.
21. **Suffix (v0.6):** non-root list files end in `.task-list.md`; task files stay `.md` (never `.task-list.md`). Contract is frontmatter `type: task-list`. `tasks/index.md` is the only `type: task-list` file allowed to keep the reserved index name.
22. **Membership dual-write (v0.6):** one skill write updates `task_list` and the list's `tasks` together. A task's `task_list` is never the root URI (loose root placement omits the field; a root target for a task is rejected before any mutation). Nested lists may set `task_list` to the root when reparented there. Pointers store the ULID URI, not the slug path. On **update**, fail closed on list self-links and list-membership cycles **before** any folder move or dual-write. Compliance walks from the root and fails if the two sides disagree, if a child list's `task_list` is not the list that points to it (including a cyclic or self list link), if a `tasks` entry is not `type: task` or `type: task-list`, or if the same ULID is already reachable in that graph.

## ULID mint (interim steward defaults)

Discuss left mint/validation open. Until a living pin replaces these, use:

- Mint a Crockford Base32 ULID (26 chars); embed in `atlas://<atlas_id>/tasks/<ULID>`.
- Timestamp from agent wall clock. `task_id` does not include the containing folder, so a ULID collision is Atlas-wide: accepting it in one list folder can create a second task or list with the same URI in another. Before accepting a ULID, walk the reachable graph from the root and compare IDs (pointer walk only — not a store-wide discovery scan). A **caller-supplied** `task_id` that is already reachable fails closed as a duplicate (never remint/replace it). An **internally minted** ULID remints once on collision, then fails closed.
- Migrate retry: if a pointer already has a well-formed `atlas://…/tasks/<ULID>` `task_id` and a matching file (ULID-only or ULID-plus-name), **preserve** that ULID (no second mint).

## File-safe name

Derive from the title: lowercase; replace runs of non-alphanumeric with a single hyphen; strip leading/trailing hyphens; cap length reasonably (e.g. 48). Empty → `item`. The slug is not identity and may change on title edit.

## Authority

- **No writes** outside an Atlas the user explicitly named for this turn.
- Fail closed if Atlas id/root is missing or ambiguous.
- Do not write discuss-atlas or any foreign store by default.
- Cross-Atlas dependency: may **name** a remote `atlas://` target and **read** it when mounted; do not write a foreign Atlas for reverse `blocks` in this cut.
- Do not run Autogenesis implement from this skill.
- Do not invent a parallel primary task type.
- Do not invent `task_status: blocked`, a stored `blocked` boolean, or a singular `assignee` field.
- Do not write or require `depends_on` — use `relates_to` dependency/blocks edges; route operators with legacy lists to **migrate**.
- Do not mint or store a kebab `display_slug` as identity.
- Do not silently accept kebab `task_id`, legacy `todo/` indexes, or `todo_id` / `todo_status` keys — route operators to **migrate**.
- Parent must be same-Atlas; cross-Atlas parent/child → fail closed.
- Do not treat a parent task as a task list. Do not use `members` as the list field. Do not copy tasks when linking lists.
- Do not discover lists/tasks by scanning the whole store — walk pointers from `tasks/index.md`.

## Enter

Every turn emits an **activation card** first — load `references/paths/activation.md`.

1. Explain-only (how it works / getting started / help / migrate, no write) → **help**, **getting-started**, or **migrate**. Card `atlas_target: none` for pure explain; migrate write steps still need a named Atlas.
2. Write paths require `atlas_target: confirmed`. Missing Atlas id → `incomplete: missing Atlas id`.
3. Route (do not conflate **add** and **complete**):
   - **add** — new task or new task list → `references/paths/add.md`
   - **complete** — existing task → done → `references/paths/complete.md`
   - **update** — change fields/body/membership/title (incl. rename) without completing → `references/paths/update.md`
   - **mount-overlay** → `references/paths/mount-overlay.md`
   - **list** / recall → `references/paths/list.md`
   - `query` (deprecated alias) → same as **list** / recall
   - **migrate** — v0.2 `todo/` → `tasks/`, `depends_on` → edges, kebab → `atlas://…/ULID`, and/or ULID-only filenames → ULID-plus-name + root index as task-list → `references/paths/migrate.md`

If the user says “create” or “add a todo”, still route to path **add** (canonical name is `add`).

## Overlay extension note

Atlas SCHEMA merge rejects overlay redeclaration of core `templates.by_type.task`. Extension is therefore:

- `claimed_folders: ["tasks"]` on contribution `atlas-tasks`
- skill-enforced frontmatter on `type: task` pointer pages (`task_id` as `atlas://…/ULID`, `task_status`, `assignees`, `parent`, `sub_tasks`, `task_list`, `relates_to` with dependency/blocks, `body_path`, …) — see `contributions/atlas-tasks/README.md`
- overlay may declare **`task-list`** as a new type (not a core redeclaration) with skill-enforced `task_id`, `tasks`, optional `task_list`
- `SCHEMA.overlay.json` carries only Atlas contract keys (no package metadata key); the normative extension contract is `contributions/atlas-tasks/README.md`

## Consumer flow

1. Install this APM package (`apm install` / clone).
2. Run path **mount-overlay** on the Atlas the user named so the v0.6 schema (including `type: task-list`) is installed before the root is converted. If the store still needs a hard-cut upgrade, run **migrate** only after that schema is installed — Checklist D must not convert the root against the old overlay.
3. Use **add** / **list** / **complete** / **update** against that Atlas (optional assignees, parent, dependency targets, task list membership on write paths).

## Non-goals

Autogenesis runtime fusion; replacing Governor/HITL queues; foreign-store writes (including remote `blocks` dual-write this cut); full realtime cross-Atlas sync; fifth status for duplicate or blocked; overlay redeclaration of core `task`; cross-Atlas parent/sub_tasks; kebab `task_id` or `display_slug` as identity; dual-read of kebab ids; legacy `todo/` read shim; keeping `depends_on` as a stored field; shops/quotes/task-lists as dependency targets; treating parent tasks as lists; store-wide scans to find lists; copying member tasks into a pointing list.
