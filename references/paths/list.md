# Path: list

Load `references/paths/activation.md` first. Card `path: list`.

1. Require at least one named Atlas for local list (or explicit “list local mount X”).
2. Open `tasks/index.md` (must be `type: task-list`). Present its `tasks` pointers — other lists and **loose** tasks only. Prefer **title + ULID**. Walk child lists by following those pointers (and ULID-prefix match inside each reached folder). **No store-wide scan.** If only legacy `todo/index.md` exists, or pointers still carry kebab `task_id` / `depends_on` / ULID-only filenames when migrate is required → fail closed / migrate debt.
3. For each task row, **derive blocked** from `relates_to` `kind: dependency` (same fail-closed remote rule as v0.5). Do not invent `task_status: blocked`. Optional columns: assignees, parent, dependency, blocks, `task_list`, derived blocked.
4. Optional remotes: only Atlases the user named; mount/read their root task list the same way. No silent foreign mounts.
5. Never dump body prose; never show a kebab slug as identity; never list a child-list member as a loose root row.
