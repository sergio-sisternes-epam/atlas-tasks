---
type: experience
title: "Implement rename atlas-todo → atlas-tasks (Autogenesis)"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-rename-atlas-tasks"
implements: "2026-09-29-atlas-todo-rename-atlas-tasks"
closes: ["2026-09-29-atlas-todo-rename-atlas-tasks"]
plan_path: autogenesis/plans/2026-09-29-atlas-todo-rename-atlas-tasks.md
status: raw
kva: alive
reality: current
description: "Autogenesis implement after explicit approval of plan 2026-09-29-atlas-todo-rename-atlas-tasks (work_id same); product atlas-tasks v0.3.0. Repository rename and tag left as separate release steps."
tags: [atlas-tasks, atlas-todo, autogenesis, implement, new-surface, rename]
origin: derived
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
  - path: autogenesis/work/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: implements
  - path: autogenesis/plans/2026-09-29-atlas-todo-rename-atlas-tasks.md
    kind: related
  - path: work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md
    kind: related
  - path: experiences/2026-09-29-atlas-todo-task-relations-implement.md
    kind: follows
---

## Context

The maintainer approved Autogenesis plan `autogenesis/plans/2026-09-29-atlas-todo-rename-atlas-tasks.md` (work_id `2026-09-29-atlas-todo-rename-atlas-tasks`) for implement. Change-class `new-surface`. Scope: rename-only v0.3.0 — package `atlas-tasks`, overlay `tasks/`, `task_id`/`task_status`, hard cut, no depends_on semantic changes. Implement stops before the irreversible release steps (repository rename, tag, consumer migrate note).

## What happened

Implemented the rename on product branch `implement/2026-09-29-atlas-todo-rename-atlas-tasks` targeting `main` (pre-publication history). Contribution moved to `contributions/atlas-tasks/`; smokes, CI, migrate path, and `references/scenarios/atlas-tasks-adversarial-v1.yaml` added. Prior atlas-todo adversarial files kept. `atlas-mesh.json` store id left as `github.com/sergio-sisternes-epam/atlas-todo` until the repository rename (discuss pin), then updated to `github.com/sergio-sisternes-epam/atlas-tasks`.

## Evaluation evidence

```text
$ bash scripts/smoke-check.sh .
PASS: 1 layout + no apm-toolkit dep
PASS: 2 overlay present + extend-not-replace (tasks/ only)
PASS: 5 fail closed without Atlas id
PASS: package-identity: atlas-tasks 0.3.0
PASS: overlay-claim: claimed_folders=[tasks], no templates.by_type.task
PASS: no-blocked-status: reject task_status:blocked; derived only
PASS: assignees-list: reject singular assignee; assignees list only
PASS: frontmatter-keys: ... task_id; no ... todo_*
PASS: status-enum: open|in_progress|done|cancelled only
PASS: dual-write / cycle-reject / depends-on-derived / depends-on-terminal / orphan-sub-tasks
PASS: 3 index + colocated body + task pointer ... + relation columns
PASS: 4 atlas compile green on fixture
PASS: 6 README install → mount
ALL SMOKES GREEN
```

## Outcome

Acceptance for the product rename met (v0.3.0). Irreversible steps deferred for maintainer approval: repository rename to `atlas-tasks`, tag `v0.3.0`, consumer migrate note, Atlas store id/path update.

## Changed files

Product (v0.3.0 → `main`):

- `apm.yml`, `SKILL.md`, `README.md`, `CHANGELOG.md`
- `contributions/atlas-todo/` → `contributions/atlas-tasks/` (SCHEMA + README)
- `references/paths/*` (+ new `migrate.md`)
- `references/scenarios/atlas-tasks-adversarial-v1.yaml` (new; v1/v2 atlas-todo kept)
- `scripts/smoke-check.sh`
- `.github/workflows/ci.yml`

Atlas lineage (`atlas` branch):

- `autogenesis/plans/2026-09-29-atlas-todo-rename-atlas-tasks.md` → implemented
- `autogenesis/work/2026-09-29-atlas-todo-rename-atlas-tasks.md` → done
- `work/2026-09-29-atlas-todo-rename-atlas-tasks.md` → done
- `work/2026-09-29-atlas-todo-rename-atlas-tasks/hub.md` → done
- this experience
- indexes / log.md

## Follow-ups

- Release: repository rename to `atlas-tasks`, tag `v0.3.0`, update Atlas store id/path (maintainer-approved)
- Installed copies retire `atlas-todo` in favour of `atlas-tasks`
- Consumer Atlases migrate `todo/` → `tasks/` and `todo_*` → `task_*` via the migrate path
- Post-v0.3.0: depends_on / relates_to work (out of this rename fence)
