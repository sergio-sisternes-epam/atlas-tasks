# Path: help

Explain atlas-tasks modules without mounting or writing. Emit activation card with `path: help`, `atlas_target: none`.

## Modules

| Path | Purpose |
|---|---|
| activation | Mandatory card before every human reply |
| getting-started | First consumer steps: install → mount → add |
| migrate | Hard-cut upgrade from atlas-todo / `todo/`, `depends_on` → edges, kebab → `atlas://…/ULID`, ULID-only → ULID-plus-name + root task-list |
| mount-overlay | Install contribution onto a user-named Atlas |
| add | **New** task or task list (`tasks/<ULID>-<name>.md` or `.task-list.md` + folder + root/list membership). Not complete. |
| update | Change status/title/body/relations/membership/rename without the complete ritual |
| complete | Mark an **existing** task done. Not add. |
| list | Recall (read) root task list and walk child lists by pointer; `query` is a deprecated alias; title + ULID; derived blocked |

## Field reminder (v0.6)

- `task_id` = `atlas://<atlas_id>/tasks/<ULID>` — never kebab, never `todo_id`; no slug in the URI
- Task path = `…/<ULID>-<file-safe-name>.md`; non-root list = `…/<ULID>-<name>/<ULID>-<name>.task-list.md`
- Root `tasks/index.md` is `type: task-list` (sole reserved-name suffix exception)
- Humans see **title + ULID** — file-safe slug is not identity; no `display_slug` identity
- `task_list` on tasks (omit when loose); list field `tasks` (not `members`); list-to-list pointer only
- Navigation = frontmatter pointer **and** body mention; membership dual-write in one skill write
- Discovery = pointer walk from root; ULID-prefix match only inside a reached folder
- `assignees: []` — never singular `assignee`
- `parent` + `sub_tasks` — dual-write; cycles forbidden; **same-Atlas**; parent ≠ list
- **No `depends_on`** — waiter `kind: dependency` + same-Atlas blocker `kind: blocks`; cross-Atlas fail-closed
- derived blocked when any `kind: dependency` target is `open` or `in_progress` (or remote unresolved)
- `task_status`: `open` | `in_progress` | `done` | `cancelled` (no `blocked`)
- Overlay claims `tasks/`; may declare type `task-list`

## Authority reminder

Writes need an explicit Atlas id. Help does not mount.
