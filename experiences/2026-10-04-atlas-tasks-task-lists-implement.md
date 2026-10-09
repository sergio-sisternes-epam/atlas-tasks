---
type: experience
title: "Implement atlas-tasks task lists (Autogenesis)"
created: "2026-10-04"
work_id: "2026-10-04-atlas-tasks-task-lists"
implements: "2026-10-04-atlas-tasks-task-lists"
closes: ["2026-10-04-atlas-tasks-task-lists"]
plan_path: autogenesis/plans/2026-10-04-atlas-tasks-task-lists.md
status: raw
kva: alive
reality: current
description: "Autogenesis implement after maintainer approval of plan 2026-10-04-atlas-tasks-task-lists; product atlas-tasks v0.6.0 task-list surface + ULID-plus-name filenames."
tags: [atlas-tasks, autogenesis, implement, new-surface, task-list]
origin: derived
sensitivity: internal
relates_to:
  - path: autogenesis/work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
  - path: work/2026-10-04-atlas-tasks-task-lists.md
    kind: implements
  - path: autogenesis/plans/2026-10-04-atlas-tasks-task-lists.md
    kind: related
  - path: discuss/atlas-tasks-task-lists/hub.md
    kind: derived_from
  - path: experiences/2026-09-29-atlas-tasks-depends-relates-to-implement.md
    kind: follows
---

## Context

The maintainer approved plan `autogenesis/plans/2026-10-04-atlas-tasks-task-lists.md` on 2026-10-04. Change-class `new-surface`. Mini-genesis artifacts were present in the plan. Scope: type `task-list`, root index as list of lists and loose tasks, `task_list`/`tasks` pointer membership, ULID-plus-name filenames, list folders, pointer-only discovery, challenge pins (URI pointers, rename rewrite, dual-write, compliance walk). Package bump **0.5.0 → 0.6.0**. Release (commit, tag) and consumer Atlas migration out of implement scope.

## What happened

Implemented atlas-tasks **v0.6.0** in the skill package (release left to the maintainer). SKILL pins 16–22; overlay declares `task-list`; contribution README; path modules add/update/list/complete/help/getting-started/migrate/mount-overlay; smoke-check extended; `references/scenarios/atlas-tasks-adversarial-v4.yaml` materialised (v1–v3 kept). Discuss work node `work/2026-10-04-atlas-tasks-task-lists.md` left in place (not deleted).

## Evaluation evidence

```text
$ bash scripts/smoke-check.sh .
PASS: 1 layout + no apm-toolkit dep
PASS: 2 overlay present + extend-not-replace (tasks/ only)
PASS: 5 fail closed without Atlas id
PASS: package-identity: atlas-tasks 0.6.0
PASS: overlay-claim: claimed_folders=[tasks], no templates.by_type.task
PASS: no-depends_on-field: skill/docs do not require depends_on
PASS: no-blocked-status: reject task_status:blocked; derived only
PASS: assignees-list: reject singular assignee; assignees list only
PASS: frontmatter-keys: atlas:// task_id + assignees/parent/sub_tasks/relates_to; no depends_on/display_slug/todo_*
PASS: status-enum: open|in_progress|done|cancelled only
PASS: task-id-atlas-uri: composite atlas://…/ULID
PASS: physical-path-ulid: tasks/<ULID>-<file-safe-name>.md
PASS: no-kebab-id: reject kebab task_id; no dual-read
PASS: human-facing-ulid: title + ULID; no display_slug
PASS: cross-atlas-dependency: remote atlas:// dependency allowed; no remote blocks write
PASS: same-atlas-parent: fail-closed: cross-Atlas parent
PASS: fail-closed-remote: unresolved remote dependency → blocked
PASS: dual-write: parent/sub_tasks both ends match after set/clear
PASS: cycle-reject: fail-closed: hierarchy cycle
PASS: orphan-sub-tasks: fail-closed-or-repaired: orphan sub_tasks
PASS: dual-write-blocks: blocker gains kind:blocks when waiter gains dependency
PASS: non-task-dependency: fail-closed: non-task dependency target
PASS: blocked-from-dependency: blocked iff any kind:dependency target open|in_progress
PASS: dependency-terminal: not-blocked when kind:dependency target cancelled
PASS: dependency-cycle: fail-closed: dependency cycle
PASS: filename-ulid-and-name: ULID-hyphen-file-safe-name
PASS: task-list-suffix-matches-type: type task-list ends in .task-list.md except tasks/index.md; type task does not
PASS: listed-task-not-loose-on-index: a task URI inside a child list is absent from root tasks
PASS: list-link-does-not-copy-tasks: a list pointer does not duplicate the target list task URIs
PASS: rename-keeps-ulid-uri: title change keeps task_id URI and ULID; slug path is not the id; no store-wide scan
PASS: member-lives-in-list-folder: task with task_list L is inside L folder; loose task is not
PASS: membership-both-sides: task_list and list tasks agree; compliance fails on drift
PASS: 3 index task-list + colocated body + ULID-plus-name pointer + list folder + dependency columns
PASS: 4 atlas compile green on fixture
PASS: 6 README install → mount
ALL SMOKES GREEN

Adversarial v4 named checks (task-list-suffix-matches-type, listed-task-not-loose-on-index,
list-link-does-not-copy-tasks, rename-keeps-ulid-uri, member-lives-in-list-folder,
membership-both-sides, filename-ulid-and-name): all exit 0.
```

## Outcome

Acceptance met for in-scope storage surface. Version **0.5.0 → 0.6.0**. Release deferred to a separate maintainer step. agent-spec Gherkin remains deferred (not in catalog). Migrating consumer Atlases deferred (out of scope).

## Changed files

Product (skill package v0.6.0):

- `SKILL.md` (v0.6.0)
- `apm.yml` (0.6.0)
- `CHANGELOG.md`
- `README.md`
- `contributions/atlas-tasks/README.md`
- `contributions/atlas-tasks/SCHEMA.overlay.json` (adds `task-list` type)
- `references/paths/add.md`
- `references/paths/update.md`
- `references/paths/list.md`
- `references/paths/complete.md`
- `references/paths/help.md`
- `references/paths/getting-started.md`
- `references/paths/migrate.md`
- `references/paths/mount-overlay.md`
- `scripts/smoke-check.sh`
- `references/scenarios/atlas-tasks-adversarial-v4.yaml` (new; v1–v3 kept)

Atlas lineage:

- `autogenesis/plans/2026-10-04-atlas-tasks-task-lists.md` → approved then implemented
- `autogenesis/work/2026-10-04-atlas-tasks-task-lists.md` → implementing then done
- `work/2026-10-04-atlas-tasks-task-lists.md` — discuss work kept (not deleted)
- this experience
- indexes / log.md

## Follow-ups

- Release: commit and tag v0.6.0 (maintainer-approved; explicitly out of this implement)
- Consumer Atlases run migrate Checklist D (ULID-only → ULID-plus-name + root task-list), on named Atlases only
- Optional agent-spec Gherkin when catalog includes agent-spec
