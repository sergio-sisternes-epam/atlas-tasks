---
type: experience
title: "Implement atlas-todo task relations / status (Autogenesis)"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
implements: "2026-09-29-atlas-todo-task-relations"
closes: ["2026-09-29-atlas-todo-task-relations"]
plan_path: autogenesis/plans/2026-09-29-atlas-todo-task-relations.md
status: raw
kva: alive
reality: current
description: "Autogenesis implement after explicit maintainer approval of plan 2026-09-29-atlas-todo-task-relations; product atlas-todo v0.2.0."
tags: [atlas-todo, autogenesis, implement, new-surface, task-relations]
origin: derived
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
  - path: autogenesis/work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
  - path: autogenesis/plans/2026-09-29-atlas-todo-task-relations.md
    kind: related
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: related
  - path: experiences/2026-09-29-atlas-todo-implement.md
    kind: follows
---

## Context

The maintainer approved plan `autogenesis/plans/2026-09-29-atlas-todo-task-relations.md` on 2026-09-29. Change-class `new-surface`. Scope: skill-enforced assignees / parent+sub_tasks dual-write / depends_on with derived blocked / four-value todo_status; INLINE path updates; overlay remains todo/ claim only; smokes + adversarial v2.

## What happened

Shipped atlas-todo **v0.2.0**: SKILL pins 6–10; contribution README field table; path modules add/update/list/complete/help/getting-started; smoke-check.sh extended with ten plan checks and `--check` selectors; `references/scenarios/atlas-todo-adversarial-v2.yaml` materialised (v1 kept).

## Evaluation evidence

```text
$ bash .apm/skills/atlas-todo/scripts/smoke-check.sh .
PASS: 1 layout + no apm-toolkit dep
PASS: 2 overlay present + extend-not-replace
PASS: 5 fail closed without Atlas id
PASS: overlay-claim: claimed_folders=[todo], no templates.by_type.task
PASS: no-blocked-status: reject todo_status:blocked; derived only
PASS: assignees-list: reject singular assignee; assignees list only
PASS: frontmatter-keys: ...
PASS: status-enum: open|in_progress|done|cancelled only
PASS: dual-write: parent/sub_tasks both ends match after set/clear
PASS: cycle-reject: fail-closed: hierarchy cycle
PASS: depends-on-derived: blocked iff any depends_on target open|in_progress
PASS: depends-on-terminal: not-blocked when depends_on target cancelled
PASS: orphan-sub-tasks: fail-closed-or-repaired: orphan sub_tasks
PASS: 3 index + colocated body + task pointer ... + relation columns
PASS: 4 atlas compile green on fixture
PASS: 6 README install → mount
ALL SMOKES GREEN

Adversarial v2 named checks (cycle-reject, orphan-sub-tasks, no-blocked-status,
assignees-list, depends-on-terminal): all PASS with expected strings.
```

## Outcome

Acceptance met. No fifth status; no `todo_status: blocked`; no `blocked_by` field; overlay still `claimed_folders: ["todo"]` with empty `templates.by_type`. Product changes land on `main`; Atlas lineage lands on the `atlas` branch.

## Changed files

Product (`main` / package):

- `.apm/skills/atlas-todo/SKILL.md` (v0.2.0)
- `.apm/skills/atlas-todo/contributions/atlas-todo/README.md`
- `.apm/skills/atlas-todo/contributions/atlas-todo/SCHEMA.overlay.json` (note only)
- `.apm/skills/atlas-todo/references/paths/add.md`
- `.apm/skills/atlas-todo/references/paths/update.md`
- `.apm/skills/atlas-todo/references/paths/list.md`
- `.apm/skills/atlas-todo/references/paths/complete.md`
- `.apm/skills/atlas-todo/references/paths/help.md`
- `.apm/skills/atlas-todo/references/paths/getting-started.md`
- `.apm/skills/atlas-todo/scripts/smoke-check.sh`
- `.apm/skills/atlas-todo/references/scenarios/atlas-todo-adversarial-v2.yaml` (new; v1 kept)
- `README.md` (v0.2 pin line)

Atlas lineage:

- `autogenesis/plans/2026-09-29-atlas-todo-task-relations.md` → implemented
- `autogenesis/work/2026-09-29-atlas-todo-task-relations.md` → done
- `work/2026-09-29-atlas-todo-task-relations.md` → done
- `work/2026-09-29-atlas-todo-task-relations/hub.md` → done
- this experience
- indexes / log.md

## Follow-ups

Optional agent-spec Gherkin (deferred in plan); cross-Atlas parent/depends_on remains non-goal.
