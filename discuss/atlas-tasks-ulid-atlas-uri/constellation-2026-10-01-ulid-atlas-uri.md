---
type: document
title: "Constellation — ULID + atlas:// identity lock (2026-10-01)"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: in-discussion
kva: alive
reality: current
consolidation: true
synonym: checkpoint
description: "Official join of the v0.5 task-identity Discuss orbit: standing pins, set-aside frames, open mint and reverse-edge protostars, and deferred package/authority items."
tags: [atlas-tasks, constellation, checkpoint, ulid, atlas-uri]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: confirms
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: confirms
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-atlas-uri-physical-path.md
    kind: confirms
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-human-facing-title-ulid.md
    kind: confirms
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-migrate-hard-cut-kebab-to-atlas-uri.md
    kind: confirms
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-cross-atlas-dependency-scope.md
    kind: confirms
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-ulid-mint-validation.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-cross-atlas-reverse-edge.md
    kind: related
---

## Standing

### Picture

v0.5-shaped atlas-tasks **identity shape** is locked in Discuss: a task’s machine id is the full physical `atlas://<atlas_id>/tasks/<ULID>` URI; humans see title + ULID (no kebab display_slug); migrate rewrites kebab ids in one hard cut with no dual-read; hierarchy (`parent` / `sub_tasks`) stays same-Atlas while `kind:dependency` / `kind:blocks` may cross via that URI (fail-closed resolve). ULID **mint and validation** and **cross-Atlas reverse-edge dual-write** remain open protostars. Package steward owns the package cut; Autogenesis stays gated.

### Confirmed

- Composite `task_id` = full `atlas://…/ULID` (not ULID-only, not split fields) — [pin-task-id-atlas-uri-composite.md](pin-task-id-atlas-uri-composite.md).
- Canonical grammar is the physical pointer path `atlas://<atlas_id>/tasks/<ULID>` → `tasks/<ULID>.md` — [pin-atlas-uri-physical-path.md](pin-atlas-uri-physical-path.md).
- Human-facing label is **title + ULID only**; no kebab `display_slug` — [pin-human-facing-title-ulid.md](pin-human-facing-title-ulid.md).
- Migrate is a **hard cut** rewrite of kebab → `atlas://…/ULID`; **no dual-read** of old ids — [pin-migrate-hard-cut-kebab-to-atlas-uri.md](pin-migrate-hard-cut-kebab-to-atlas-uri.md).
- **`parent` / `sub_tasks` same-Atlas only**; **`kind:dependency` / `kind:blocks` may cross** Atlases — [pin-cross-atlas-dependency-scope.md](pin-cross-atlas-dependency-scope.md).
- Living thesis matches the pins — [current-reality.md](current-reality.md).

### Expanded

- Cross-Atlas scope split hierarchy vs dependency (was a single open “lift non-goal?” question; now a standing pin with an explicit same-Atlas hierarchy fence).

## Set aside

### Refuted

- Option A: ULID-only `task_id` with derived `atlas://` (home store not in the id).
- Option C: split ULID field + separate atlas URI field.
- Keeping a kebab `display_slug` as a second human id.
- Dual-read / long alias window for kebab ids after the cut.
- Cross-Atlas `parent` / `sub_tasks`.

### Deferred

- **Fail-closed foreign resolve details** (exact blocked/error behaviour when a remote `atlas://` dependency target is unknown, unmounted, or unreadable) — required by the cross-Atlas pin, owned by package steward (package cut), not re-opened as identity shape here.
- **No Autogenesis / no package implement** until the maintainer unlocks it.
- **Package steward owns the v0.5 package cut** after this Discuss lock.

## Still open

### Gaps

- **ULID mint and validation** — timestamp source, monotonic generation, collision handling, preserve already-minted ID on migration retry — [protostar-ulid-mint-validation.md](protostar-ulid-mint-validation.md). Identity-shape pins do not cover mint behaviour.
- **Cross-Atlas reverse-edge / dual-write** — one-way vs coordinated remote `kind:blocks`, write authority, failure/retry — [protostar-cross-atlas-reverse-edge.md](protostar-cross-atlas-reverse-edge.md). The cross-Atlas scope pin locks allowance + fail-closed resolve only.
- Remaining package implementation authority (unlock + package steward) is gated, not a Discuss identity-shape gap.

### Contradictions

- None among standing pins. The v0.4 “dependency/blocks same-Atlas only” pin is superseded **for Atlas-boundary scope** by the cross-Atlas dependency pin; targets remain task pointers / task ids (body files and non-task notes such as reviewer or sign-off pages still fail closed).
