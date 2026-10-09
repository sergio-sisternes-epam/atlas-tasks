# Path: activation

Mandatory prefix on every atlas-tasks turn that will reply to a human. Emit the card **before** any human-facing prose. Missing card ⇒ `incomplete: missing activation card`.

## Card (always)

```text
skill: atlas-tasks
skill_path: <this skill root>
path: <help|getting-started|migrate|mount-overlay|add|update|complete|list>
path_module: references/paths/<path>.md
atlas_id: <named id | unknown>
atlas_root: <resolved root | unknown>
atlas_target: <confirmed | unknown | none>
intent: <one line>
task_id: <id if known | none>
speak_loaded: n/a
```

## Rules

- `atlas_target: none` only for help / getting-started explain-only turns (and migrate explain before a named Atlas).
- Any write path (`mount-overlay`, `add`, `update`, `complete`, migrate apply) requires `atlas_target: confirmed` and a non-empty `atlas_id` / root. Otherwise stop: `incomplete: missing Atlas id`.
- Do not treat the card as execution evidence; it is the request interface only.
- After the card, load the selected path module and follow it.
