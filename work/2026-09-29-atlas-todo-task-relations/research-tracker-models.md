---
type: document
title: "Research — Jira / ADO / GitHub Issues relationship models"
created: "2026-09-29"
work_id: "2026-09-29-atlas-todo-task-relations"
status: probed
kva: alive
description: "Third-party models for hierarchy vs dependency vs assignee, to ground atlas-todo v0.2 fields."
tags: [atlas-todo, research, jira, azure-devops, github-issues]
origin: third-party
sensitivity: public
relates_to:
  - path: work/2026-09-29-atlas-todo-task-relations/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-todo-task-relations.md
    kind: implements
---

## Content

Cross-cutting pattern across all three trackers: **hierarchy and dependency are separate**. Ownership (assignee) is a third orthogonal axis.

### Jira

- **Hierarchy** is not an issue link. Sub-tasks and Epic/parent use a `parent` field (and Epic Link / parentEpic). One parent; children queried via parent / parentEpic.
- **Dependency** uses configurable issue links: notably **Blocks** (`blocks` / `is blocked by`) and **Depends** (`depends on` / `is depended on by`). Links are bidirectional for UI labels; many-to-many.
- **Assignee** is a first-class person field (typically single).

Sources: Atlassian issue-linking model; Jira Cloud Epic child/linked JQL guidance.

### Azure DevOps

- **Hierarchy:** system **Parent / Child** (tree topology). One parent; many children; cycles forbidden.
- **Dependency:** **Predecessor / Successor** (dependency topology). Predecessor must finish before the current item; successor after. Cycles error.
- **Blocked** can also appear as a **process field/flag** on boards, separate from link topology.
- **Assigned To** is first-class.

Source: Microsoft Learn link-type reference (Parent/Child, Predecessor/Successor).

### GitHub Issues

- **Hierarchy:** **parent** and **sub-issues** (Issues 2.0). One parent per issue; nested sub-issues allowed (documented up to eight levels). Managed via Relationships UI and `gh` (`--parent`, `--add-sub-issue`).
- **Dependency:** **blocked by** / **blocking** (GA 2025-08-21). Separate from parent/sub-issue. Search: `is:blocked`, `blocked-by:`, etc. `gh` exposes `--blocked-by` / `--blocking`.
- **Assignees:** multi-assignee supported on issues.

Sources: GitHub docs creating issue dependencies; GitHub changelog dependencies GA; GitHub docs/CLI for sub-issues.

## Consensus for atlas-todo

1. Do **not** overload parent/child with blocked-by.
2. Prefer **one parent** (tree), not many parents.
3. Store dependency as **directional lists of todo_ids**; treat “blocked” display as **derived** when any blocker is still open — do not require a separate `todo_status: blocked` (v1 already omits blocked).
4. Assignee is orthogonal to both graphs.

## Provenance

Fetched 2026-09-29 from Atlassian, Microsoft Learn, and GitHub docs/changelogs during Discuss for work_id 2026-09-29-atlas-todo-task-relations.
