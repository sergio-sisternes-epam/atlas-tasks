---
type: experience
title: "Implement atlas-todo skill + overlay (Autogenesis)"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo"
implements: "2026-09-29-atlas-todo"
closes: ["2026-09-29-atlas-todo"]
plan_path: autogenesis/plans/2026-09-29-atlas-todo.md
status: raw
description: "Autogenesis implement after explicit approval of plan 2026-09-29-atlas-todo."
tags: [atlas-todo, autogenesis, implement]
relates_to:
  - path: work/2026-09-29-atlas-todo.md
    kind: implements
  - path: autogenesis/plans/2026-09-29-atlas-todo.md
    kind: related
---

## Context

The maintainer approved plan `autogenesis/plans/2026-09-29-atlas-todo.md` on 2026-09-29. Design-review corrections carried into implement: layout is a single APM package tree; the write path stays named **add** (not create); **add** and **complete** are separate paths; each path opens with an Autogenesis-style activation card.

## What happened

Shipped `.apm/skills/atlas-todo/` with paths activation, add, update, complete, list, mount-overlay, help, getting-started; overlay claiming `todo/`; README; smokes. Core `task` extended via skill frontmatter (SCHEMA forbids redeclaration).

## Evaluation evidence

```text
$ bash .apm/skills/atlas-todo/scripts/smoke-check.sh .
ALL SMOKES GREEN
```

## Outcome

Acceptance met; path modules follow the design-review corrections; package shipped on `main` as v0.1.

## Changed files

Product (`main`): `.apm/skills/atlas-todo/**`, `README.md`

Atlas lineage: plan → implemented; work → done; this experience.

## Follow-ups

Optional agent-spec Gherkin; richer remote index coordination.
