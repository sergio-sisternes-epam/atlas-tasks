---
type: document
title: "Current reality — task identity v0.5 Discuss"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: in-discussion
kva: alive
reality: current
description: "Living thesis for ULID + atlas:// task identity. Records the v0.4 baseline and the maintainer's pins through human-facing, hard-cut migrate, and cross-Atlas scope; mint/validation remains open."
tags: [atlas-tasks, living-thesis, ulid, atlas-uri]
origin: derived
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-atlas-uri-physical-path.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-human-facing-title-ulid.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-migrate-hard-cut-kebab-to-atlas-uri.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-cross-atlas-dependency-scope.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-ulid-mint-validation.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/constellation-2026-10-01-ulid-atlas-uri.md
    kind: related
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Living thesis

### Inherited from v0.4 (superseded where pins below say so)

- `task_id` today (pre-cut) is a **kebab slug** (human-readable, Atlas-local).
- Parent and dependency targets were **same-Atlas pointer paths** only.
- **Cross-Atlas** task targeting was an explicit **non-goal** for v0.4.

### Why this orbit exists

We want tasks that can traverse Atlases: a globally unique mint (ULID) plus a home-store trace (`atlas://…`) so a dependency can name a task that lives elsewhere without losing where to resolve it.

### Authority fence

- Discuss lives on this package Atlas (`github.com/sergio-sisternes-epam/atlas-tasks`, branch `atlas`).
- Package steward owns the v0.5 package cut after Discuss locks the identity.
- No Autogenesis / implement until the maintainer unlocks it.

### Pins standing

1. **`task_id` is the full `atlas://…/ULID` composite string** — see [pin-task-id-atlas-uri-composite.md](pin-task-id-atlas-uri-composite.md). Not ULID-only with a derived URI; not separate fields.
2. **The canonical grammar is the physical path** `atlas://<atlas_id>/tasks/<ULID>`, resolving to the home store's `tasks/<ULID>.md` pointer — see [pin-atlas-uri-physical-path.md](pin-atlas-uri-physical-path.md). Fragments such as `#task/<ULID>` are not primary ids.
3. **Human-facing = title + ULID only** — no kebab `display_slug` — see [pin-human-facing-title-ulid.md](pin-human-facing-title-ulid.md).
4. **Migrate hard cut** — rewrite all kebab `task_id`s to `atlas://…/ULID`; **no dual-read** of old ids — see [pin-migrate-hard-cut-kebab-to-atlas-uri.md](pin-migrate-hard-cut-kebab-to-atlas-uri.md).
5. **Hierarchy same-Atlas; dependency/blocks may cross** — `parent` / `sub_tasks` stay same-Atlas; `kind:dependency` / `kind:blocks` may target other Atlases with fail-closed resolve — see [pin-cross-atlas-dependency-scope.md](pin-cross-atlas-dependency-scope.md).

### Open (do not decide alone)

- **ULID mint and validation** — timestamp source, monotonic generation, collision handling, preserve already-minted ID on migration retry — see [protostar-ulid-mint-validation.md](protostar-ulid-mint-validation.md). Not claimed complete with the identity-shape lock.
- Package cut / Autogenesis remains gated on the maintainer’s unlock (authority fence), not an open Discuss identity-shape protostar beyond mint.

## Related

- [Hub](hub.md)
- [Pin — composite task_id](pin-task-id-atlas-uri-composite.md)
- [Protostar — ULID mint and validation](protostar-ulid-mint-validation.md)
- [Constellation — 2026-10-01](constellation-2026-10-01-ulid-atlas-uri.md)
