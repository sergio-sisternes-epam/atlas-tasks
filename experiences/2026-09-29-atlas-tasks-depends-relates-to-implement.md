---
type: experience
title: "Implement atlas-tasks depends → relates_to dependency/blocks (Autogenesis)"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
implements: "2026-09-29-atlas-tasks-depends-relates-to"
closes: ["2026-09-29-atlas-tasks-depends-relates-to"]
plan_path: autogenesis/plans/2026-09-29-atlas-tasks-depends-relates-to.md
status: raw
kva: alive
reality: current
description: "Autogenesis implement after explicit approval of plan 2026-09-29-atlas-tasks-depends-relates-to; gate v0.3.0 tagged satisfied; product v0.4.0."
tags: [atlas-tasks, autogenesis, implement, new-surface, dependency, relates_to]
origin: derived
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
  - path: autogenesis/work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
  - path: autogenesis/plans/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: related
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: related
  - path: experiences/2026-09-29-atlas-todo-task-relations-implement.md
    kind: follows
---

## Context

The maintainer approved plan `autogenesis/plans/2026-09-29-atlas-tasks-depends-relates-to.md` with the gate “implement after v0.3.0 is tagged”. Tag **v0.3.0** published; gate satisfied. Change-class `new-surface`. Scope: remove `depends_on`; waiter `relates_to` `kind: dependency` + blocker dual-write `kind: blocks`; derived blocked from dependency edges; same-Atlas task pointer targets only; migrate path; smokes + adversarial v2; package bump **0.4.0**.

## What happened

Shipped atlas-tasks **v0.4.0** on product branch `implement/2026-09-29-atlas-tasks-depends-relates-to` targeting `main` (pre-publication history). SKILL pins 8/9/12; contribution README field table; path modules add/update/list/complete/help/getting-started/migrate; smoke-check.sh rewritten; `references/scenarios/atlas-tasks-adversarial-v2.yaml` materialised (v1 kept). Consumer migration left as a follow-up.

## Evaluation evidence

```text
$ bash scripts/smoke-check.sh .
PASS: 1 layout + no apm-toolkit dep
PASS: 2 overlay present + extend-not-replace (tasks/ only)
PASS: 5 fail closed without Atlas id
PASS: package-identity: atlas-tasks 0.4.0
PASS: overlay-claim: claimed_folders=[tasks], no templates.by_type.task
PASS: no-depends_on-field: skill/docs do not require depends_on
PASS: no-blocked-status: reject task_status:blocked; derived only
PASS: assignees-list: reject singular assignee; assignees list only
PASS: frontmatter-keys: ... relates_to ...; no depends_on
PASS: status-enum: open|in_progress|done|cancelled only
PASS: dual-write: parent/sub_tasks both ends match after set/clear
PASS: cycle-reject: fail-closed: hierarchy cycle
PASS: orphan-sub-tasks: fail-closed-or-repaired: orphan sub_tasks
PASS: dual-write-blocks: blocker gains kind:blocks when waiter gains dependency
PASS: non-task-dependency: fail-closed: non-task dependency target
PASS: blocked-from-dependency: blocked iff any kind:dependency target open|in_progress
PASS: dependency-terminal: not-blocked when kind:dependency target cancelled
PASS: dependency-cycle: fail-closed: dependency cycle
PASS: 3 index + colocated body + task pointer ... + dependency columns
PASS: 4 atlas compile green on fixture
PASS: 6 README install → mount
ALL SMOKES GREEN

Adversarial v2 named checks (no-depends_on-field, non-task-dependency,
dual-write-blocks, blocked-from-dependency): all PASS with expected strings.
```

## Outcome

Acceptance met. No `depends_on` required; dual-write dependency/blocks; non-task reject; blocked from dependency edges; cycles forbidden. Released as atlas-tasks v0.4.0.

## Changed files

Product (`main` / package v0.4.0):

- `SKILL.md` (v0.4.0)
- `apm.yml` (0.4.0)
- `CHANGELOG.md`
- `README.md`
- `contributions/atlas-tasks/README.md`
- `contributions/atlas-tasks/SCHEMA.overlay.json` (note)
- `references/paths/add.md`
- `references/paths/update.md`
- `references/paths/list.md`
- `references/paths/complete.md`
- `references/paths/help.md`
- `references/paths/getting-started.md`
- `references/paths/migrate.md`
- `scripts/smoke-check.sh`
- `references/scenarios/atlas-tasks-adversarial-v2.yaml` (new; v1 kept)

Atlas lineage:

- `autogenesis/plans/2026-09-29-atlas-tasks-depends-relates-to.md` → implemented
- `autogenesis/work/2026-09-29-atlas-tasks-depends-relates-to.md` → done
- `work/2026-09-29-atlas-tasks-depends-relates-to.md` → done
- `work/2026-09-29-atlas-tasks-depends-relates-to/hub.md` → done
- this experience
- indexes / log.md

## Follow-ups

- Release: tag v0.4.0 (maintainer-approved)
- Consumer Atlases migrate `depends_on` lists (e.g. T16 *Publish release notes* → T15 *Tag release candidate*) to dependency/blocks edges via the migrate path
- Optional agent-spec Gherkin (deferred in plan); cross-Atlas dependency remains non-goal
