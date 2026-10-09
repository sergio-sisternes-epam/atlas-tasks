---
type: decision
title: "Pin — remove depends_on; relates_to kind:dependency only"
created: "2026-09-29"
work_id: "2026-09-29-atlas-tasks-depends-relates-to"
status: accepted
kva: alive
reality: current
description: "Living pin: drop depends_on field; express waits only as relates_to kind:dependency; migrate existing depends_on lists to edges."
tags: [atlas-tasks, pin, depends_on, relates_to]
origin: user
sensitivity: internal
relates_to:
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/hub.md
    kind: derived_from
  - path: work/2026-09-29-atlas-tasks-depends-relates-to/problem-dependency-writeup.md
    kind: follows
  - path: work/2026-09-29-atlas-tasks-depends-relates-to.md
    kind: implements
---

## Decision

**Remove** the `depends_on: []` field. Canonical dependency is **`relates_to` with `kind: dependency`**. Migrate existing `depends_on` entries to those edges. No derived-cache dual-write of `depends_on`.

## Consequences

- Skill add/update/list/complete stop reading/writing `depends_on`.
- Derived blocked scans `relates_to` edges with `kind: dependency`.
- Consumer Atlases that adopted v0.2 need a one-shot migrate of `depends_on` lists → `kind: dependency` edges.
- Supersedes v0.2 pin that made `depends_on` the canonical stored field (for post-v0.3 work).

## Provenance

Approved by the maintainer on 2026-09-29, in response to the [consumer write-up](problem-dependency-writeup.md).
