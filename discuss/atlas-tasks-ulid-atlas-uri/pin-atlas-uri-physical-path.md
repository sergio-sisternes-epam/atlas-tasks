---
type: decision
title: "Pin — atlas:// task_id uses the physical tasks/<ULID> pointer path"
created: "2026-10-01"
updated: "2026-10-01"
work_id: "2026-10-01-atlas-tasks-ulid-atlas-uri"
status: accepted
kva: alive
reality: current
description: "Living pin: task_id is the canonical atlas:// URI whose path resolves to the task pointer at tasks/<ULID>.md."
tags: [atlas-tasks, pin, ulid, atlas-uri, task-id, path]
origin: user
sensitivity: internal
relates_to:
  - path: discuss/atlas-tasks-ulid-atlas-uri/pin-task-id-atlas-uri-composite.md
    kind: follows
  - path: discuss/atlas-tasks-ulid-atlas-uri/protostar-atlas-uri-grammar.md
    kind: kva_supersede
  - path: discuss/atlas-tasks-ulid-atlas-uri/current-reality.md
    kind: related
  - path: discuss/atlas-tasks-ulid-atlas-uri/hub.md
    kind: derived_from
  - path: work/2026-10-01-atlas-tasks-ulid-atlas-uri.md
    kind: implements
---

## Decision

The canonical v0.5-shaped `task_id` is the full path-form URI:

```text
atlas://<atlas_id>/tasks/<ULID>
```

`<atlas_id>` is the scheme-free canonical Atlas id (`host/owner/repository`), and `<ULID>` is a 26-character Crockford ULID. For example:

```text
atlas://github.com/sergio-sisternes-epam/atlas-tasks/tasks/01J8E3K7M4Q2V8X5N6P9R0T1YZ
```

The `/tasks/<ULID>` URI path is the physical pointer path under the home Atlas store. Under the current pointer convention it resolves to:

```text
<atlas_root>/tasks/<ULID>.md
```

The resolver applies the skill's pointer-page convention, but the URI path remains the claimed `tasks/` path and must continue to identify that pointer file. `task_id` **is** this exact `atlas://` URI; it is not a ULID-only value and has no separately derived home-store field.

The canonical form has no fragment, query, or suffix. In particular, `#task/<ULID>` is not a primary identity because a fragment does not identify the physical pointer location. Malformed, unknown, unmounted, or unreadable home stores resolve fail-closed.

## Provenance

Pinned by the maintainer on 2026-10-01: the id must point to the physical location of the task so any agent can traverse Atlases and find the information. Supersedes the open question in [protostar-atlas-uri-grammar.md](protostar-atlas-uri-grammar.md).
