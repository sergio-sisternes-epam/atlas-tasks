# atlas-tasks

Distributed Atlas **task** discipline for agents that already use Atlas: per-Atlas `tasks/index.md` as the root **task list**, colocated task bodies, core Atlas `task` pages as pointers, and `type: task-list` pages for named groupings.

Formerly **atlas-todo** (≤ v0.2). v0.3 renamed package/overlay/keys. v0.4 removed `depends_on` for `relates_to` dependency/blocks. v0.5 made `task_id` the full `atlas://<atlas_id>/tasks/<ULID>` composite. **v0.6.0** adds task lists (own file/folder, `task_list`/`tasks` pointers) and ULID-plus-name filenames. **v0.6.2** drops the informational `atlas_tasks` key from the overlay so it installs on SCHEMA 2.0 stores. **v0.6.3** renames the read verb from query to recall (query stays a deprecated alias).

## Capabilities

- Add, update, complete, and list tasks across Atlases the user names
- Create and maintain task lists (own `.task-list.md` + folder; root index is the list of lists and loose tasks)
- Mount the atlas-tasks overlay onto an indicated Atlas
- Keep index/list rows as pointers; bodies stay beside related knowledge nodes
- Dual-write same-Atlas dependency edges and task-list membership; derive blocked from open/in_progress dependency targets
- Name remote tasks with `atlas://…/ULID` on dependency edges (fail-closed resolve)

## Prerequisites

- Atlas CLI available (`atlas` skill / `scripts/atlas.py`)
- A target Atlas the user names (no silent foreign-store writes)

## Installation

```bash
python3 <atlas-skill>/scripts/atlas.py schema install \
  <atlas-tasks-package>/contributions/atlas-tasks \
  --root <your-atlas-root>
python3 <atlas-skill>/scripts/atlas.py compile --root <your-atlas-root>
```

Canonical install pin after publish: `sergio-sisternes-epam/atlas-tasks#v0.6.3`.

Upgrading from v0.6.1 or older: rerun the same `schema install` (no `--force`), and do it before any `schema upgrade --to 2.0`.

## First success

1. Name a target Atlas and run the skill path `mount-overlay`.
2. Run path `add` with a related node path and title (skill mints ULID + `atlas://` `task_id`; file is `tasks/<ULID>-<name>.md`).
3. Confirm `tasks/index.md` is `type: task-list`, gained a loose pointer row, and `atlas compile` is green.

## Migrate

- **From atlas-todo (v0.2):** hard cut to `tasks/` + `task_id` / `task_status` — see skill path `migrate`.
- **From v0.3 `depends_on`:** convert to waiter `kind: dependency` + blocker `kind: blocks`; drop `depends_on`.
- **From kebab ids (≤ v0.4):** mint ULID per task; rewrite to `atlas://…/ULID`; **no dual-read**.
- **From ULID-only filenames (v0.5):** rename to `<ULID>-<file-safe-name>`; convert root index to `type: task-list`; optional list folders.

## Design pins

- Extends core `task`; overlay adds `task-list`
- Complements Governor tasks / APM HITL queues
- Index holds pointers only; humans see title + ULID
- v0.6: task lists + ULID-plus-name paths; hierarchy same-Atlas; dependency/blocks may cross; no kebab slug identity
- Overlay carries only Atlas contract keys; the normative extension contract is `contributions/atlas-tasks/README.md`

## Smokes

```bash
ATLAS_CLI=<atlas-skill>/scripts/atlas.py bash scripts/smoke-check.sh .
bash scripts/public-hygiene-scan.sh --all
```

`ATLAS_CLI` is optional when the `atlas` skill is installed as a sibling of this package (`../atlas/scripts/atlas.py`).

The SCHEMA 2.0 smokes need the Python `jsonschema` package (`pip install jsonschema`); the check fails if it is missing.

## Support

Source: https://github.com/sergio-sisternes-epam/atlas-tasks

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
