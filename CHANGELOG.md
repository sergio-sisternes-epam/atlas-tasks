# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.3] - 2026-10-09

### Changed

- Rename the read verb from `query` to `recall`, keeping `query` as a deprecated alias routing to `list`.

### Added

- Smoke checks `recall-alias` and `no-mandatory-notes-or-vault-tool`.

### Not changed

- No page, frontmatter, schema-key, or overlay change; no reinstall needed.

## [0.6.2] - 2026-10-09

### Fixed

- The overlay now installs on Atlas SCHEMA 2.0 stores (Atlas 0.10.0 to 0.13.0, including 0.12.0 and 0.13.0). Before this fix, `atlas schema install` failed with `$: Unevaluated properties are not allowed ('atlas_tasks' was unexpected)`. `contributions/atlas-tasks/SCHEMA.overlay.json` now carries only Atlas contract keys.
- The informational `atlas_tasks` overlay object (extended core type, extension mode, and the version-cut note) moved to `contributions/atlas-tasks/README.md`, which is now the normative extension contract. Nothing read the key.

### Added

- `scripts/smoke-check.sh` check `overlay-root-keys`: overlay root keys must be a subset of `contribution_id`, `claimed_folders`, `templates`, `types`, `bindings`, `presets`.
- `scripts/smoke-check.sh` runs the install + compile fixture on both a default `init` store and an `init --schema-version 2.0` store, and reads `atlas_id` from `CONTRACT.json` (Atlas 0.13+) or `SCHEMA.json`. The SCHEMA 2.0 run needs the Python `jsonschema` package and fails closed without it; CI installs `jsonschema==4.25.1`.

### Not changed

- No page, frontmatter, or schema-key changes. `contribution_id`, `claimed_folders` and `templates` are identical to v0.6.1.

### Upgrade

- Reinstall the overlay with `schema install` on each Atlas that holds it. `--force` is not needed.
- On SCHEMA 1.0 stores, reinstall **before** any `schema upgrade --to 2.0`. A store that still holds the v0.6.1 (or older) overlay can report the upgrade as ok and then fail compile.

## [0.6.1] - 2026-10-09

First public release. No behaviour change.

### Changed

- Public release of the package at `github.com/sergio-sisternes-epam/atlas-tasks`.
- `scripts/smoke-check.sh` resolves the Atlas CLI from the `ATLAS_CLI` environment variable or, failing that, the sibling installed `atlas` skill (`../atlas/scripts/atlas.py`); no machine-specific paths. It exits 2 with a clear message when neither is found.
- Atlas store submodule repointed to this repository's `atlas` branch (`.atlas/github.com/sergio-sisternes-epam/atlas-tasks`).

### Added

- Apache-2.0 `LICENSE` and `NOTICE`.
- Public hygiene CI scan (`scripts/public-hygiene-scan.sh`, job `Public hygiene scan`): tree deny-list, commit metadata, added lines, and gitleaks.

### Fixed

- Review follow-ups to the task-list release: Atlas-wide ULID collision walk, nested-list folder moves, reciprocal list parent and fail-closed target type in the compliance walk, exact `tasks/index.md` suffix, duplicated "only", and one v0.5→v0.6 order that installs the overlay before converting the root.

## [0.6.0] - 2026-10-04

### Added

- **Task lists** as their own surface: `type: task-list`, own file, own folder. Parent/`sub_tasks` hierarchy stays separate — a parent is not a list.
- Root `tasks/index.md` is itself a task list (`type: task-list`) of other lists and loose tasks. A task in a child list is not also a loose row on the index.
- Membership fields: task `task_list` (omit when loose); list `tasks` (pointers to tasks or other lists — not `members`, not `parent`/`sub_tasks`).
- List-to-list is pointer-only (no task copy). Navigation = frontmatter pointer **and** a body mention of that member.
- Non-root list files end in `.task-list.md`; live in a folder named `<ULID>-<file-safe-name>/`. Contract is frontmatter `type: task-list`. `tasks/index.md` is the only `type: task-list` file allowed the reserved index name.
- Discovery walks pointers from the root only — no store-wide scan. Inside a folder already reached by a pointer, a stale filename may match by ULID prefix only.
- Challenge pins: pointers store ULID URIs (not slug paths); a title change renames the file and rewrites body mentions in the same skill write; one skill write updates `task_list` and the list's `tasks` together; compliance walks from the root and fails if the two sides disagree.
- Adversarial scenario `references/scenarios/atlas-tasks-adversarial-v4.yaml` (v1–v3 kept).

### Changed

- **Breaking:** task and task-list filenames are `<ULID>-<file-safe-name>` (ULID first, hyphen, file-safe name). ULID-only task filenames are no longer the shape the skill writes. Identity remains the ULID inside `atlas://<atlas_id>/tasks/<ULID>`.
- Paths add/update/list/complete/help/getting-started/migrate/mount-overlay updated for task lists, ULID-plus-name paths, and membership dual-write.
- Smoke-check extended for suffix, folder membership, index no-duplicate-loose, list-link no-copy, rename-keeps-URI, both-sides membership.

### Not changed

- `task_id` URI grammar (`atlas://<atlas_id>/tasks/<ULID>`); assignees list; four-value `task_status`; derived blocked; `parent`/`sub_tasks` same-Atlas dual-write; dependency/blocks (incl. cross-Atlas fail-closed); package/overlay identity `atlas-tasks` / `tasks/` claim; no `depends_on`; no kebab `task_id` / `display_slug`.

## [0.5.0] - 2026-10-01

### Changed

- **Breaking:** `task_id` is the full `atlas://<atlas_id>/tasks/<ULID>` composite (not a kebab slug). Pointer files live at `tasks/<ULID>.md` (flattened from nested `tasks/tasks/<kebab>.md`).
- **Breaking:** human-facing label is **title + ULID** only — no kebab `display_slug`.
- **Breaking:** migrate hard-cuts every kebab `task_id` (and kebab-as-id references) → `atlas://…/ULID`; **no dual-read** of old kebab ids.
- **Breaking:** `parent` / `sub_tasks` store same-Atlas `atlas://…/ULID` ids only; cross-Atlas hierarchy fails closed.
- `kind: dependency` / `kind: blocks` may target other Atlases via `atlas://` with **fail-closed** resolve (unknown/unmounted/unreadable → unresolved/blocked, never ok-because-missing). Same-Atlas dual-write (`dependency` ↔ `blocks`) unchanged.
- Cross-Atlas reverse `blocks` write is **not** implemented this cut (open Discuss protostar); local waiter may record a remote dependency edge without mutating the foreign store.
- Interim ULID mint defaults documented in SKILL (wall clock, collision remint once, preserve id on migrate retry) until Discuss pins mint/validation.
- Paths add/update/list/complete/help/getting-started/migrate updated; smoke-check and adversarial v3 cover URI identity, flatten path, no-kebab, cross-Atlas dependency allow + parent reject, fail-closed remote.

### Not changed

- Assignees list; four-value `task_status`; derived blocked terminal rule; package/overlay identity `atlas-tasks` / `tasks/` claim; no `depends_on`.

## [0.4.0] - 2026-09-29

### Changed

- **Breaking:** remove canonical `depends_on: []` field. Waits are expressed as `relates_to` edges — waiter **`kind: dependency`**, blocker dual-write **`kind: blocks`**.
- **Breaking:** dependency/blocks targets are same-Atlas `type: task` **pointer paths** only (not `task_id` lists, bodies, shops, quotes, or cross-Atlas). Fail closed otherwise.
- Derived blocked now scans waiter `kind: dependency` targets (same terminal rule: blocked while any target is `open` | `in_progress`; `done` | `cancelled` clear).
- Paths add/update/list/complete/help/getting-started/migrate updated; migrate converts `depends_on` lists → path edges + reverse `blocks` and drops the key.
- Smoke-check rewritten for dependency-edge dual-write, non-task reject, and no-`depends_on` contract; adversarial scenario `atlas-tasks-adversarial-v2.yaml` added (v1 kept).

### Not changed

- Assignees list, parent/`sub_tasks` dual-write hierarchy.
- Package/overlay identity `atlas-tasks` / `tasks/` / `task_id` / `task_status` from v0.3.0.

## [0.3.0] - 2026-09-29

### Changed

- **Breaking:** package and skill identity renamed from `atlas-todo` to `atlas-tasks`.
- **Breaking:** overlay claim `todo/` → `tasks/` (`tasks/index.md`); contribution folder `contributions/atlas-tasks/`.
- **Breaking:** pointer keys `todo_id` → `task_id`, `todo_status` → `task_status` (enum unchanged: `open` | `in_progress` | `done` | `cancelled`).
- Hard cut: no read shim for `todo/`, `todo_id`, or `todo_status`; migrate path documented.
- Smoke-check and CI updated for new ids/paths; adversarial scenario `atlas-tasks-adversarial-v1.yaml` added (prior atlas-todo adversarial files kept as history).

### Not changed

- `depends_on` / derived-blocked semantics (rename-only fence; deferred post-v0.3.0).
- Assignees list, parent/`sub_tasks` dual-write hierarchy.

## [0.2.0] - 2026-09-29

### Added

- Multi-assignee ownership via `assignees: []` (singular `assignee` forbidden).
- Parent / `sub_tasks` dual-write hierarchy with cycle rejection.
- Canonical `depends_on: []` with derived blocked (no `todo_status: blocked`).
- Four-value `todo_status`: `open` | `in_progress` | `done` | `cancelled`.
- GitHub Actions CI (`compile` + smoke) and tag-triggered release workflow.

### Changed

- Converted packaging to APM HYBRID root-skill layout (`SKILL.md` at package root;
  removed nested `.apm/skills/atlas-todo/`).
- Aligned `apm.yml` version with skill metadata at `"0.2.0"`.

[Unreleased]: https://github.com/sergio-sisternes-epam/atlas-tasks/compare/v0.6.3...HEAD
[0.6.3]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.6.3
[0.6.2]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.6.2
[0.6.1]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.6.1
[0.6.0]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.6.0
[0.5.0]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.5.0
[0.4.0]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.4.0
[0.3.0]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.3.0
[0.2.0]: https://github.com/sergio-sisternes-epam/atlas-tasks/releases/tag/v0.2.0
