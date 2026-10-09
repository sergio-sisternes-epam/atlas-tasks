# Path: mount-overlay

Load `references/paths/activation.md` first. Card `path: mount-overlay`.

## Preconditions

- User named a concrete Atlas id or `--root` path.
- Atlas skill CLI available: `python3 <atlas-skill>/scripts/atlas.py`

## Steps

1. Resolve `--root` for the named Atlas (`atlas resolve` / known mount). Fail closed if unknown.
2. The v0.6 overlay is installed before the root is converted to `type: task-list`. Do not run Checklist D, and do not rewrite `tasks/index.md` as `type: task-list`, against the old schema.
   - If the Atlas still has `todo/` without `tasks/`, or pointers still use kebab `task_id` / nested `tasks/tasks/<kebab>.md` from ≤ v0.4, stop and route to **migrate** checklists A–C (hard cut — do not mount beside an unmigrated surface). Those checklists install this overlay before Checklist D.
   - If the store is v0.5 (`atlas://` ids, ULID-only filenames): continue this mount so the new schema is installed **first**, then route filename renames and the root conversion to **migrate** Checklist D. Checklist D is not optional-before-mount, and it is not a conversion that runs without this install.
3. Install the packaged contribution:

```bash
python3 <atlas-skill>/scripts/atlas.py schema install \
  <atlas-tasks-skill>/contributions/atlas-tasks \
  --root <named-atlas-root> [--force]
```

4. Compile:

```bash
python3 <atlas-skill>/scripts/atlas.py compile --root <named-atlas-root>
```

5. After schema install + compile, ensure or create `tasks/index.md` as `type: task-list` **only** when this is a new install or the store is already v0.6 (root already `type: task-list`, or the overlay is present as expected with no document-style v0.5 index left to convert). Create a stub if missing — see add path index contract — and compile again if created.
   - If the store is still v0.5 (`atlas://` ids, ULID-only filenames, document-style root index not yet `type: task-list`): do **not** rewrite `tasks/index.md` here. Leave the document index for **migrate** Checklist D (filename inventory, collision handling, and membership rewrite) after this install, as in step 2.
6. Report overlay id `atlas-tasks`, claimed folder `tasks/`, URI identity (`atlas://…/tasks/<ULID>`), filename shape `<ULID>-<name>`, task-list type available, and that core `task` is extended via skill contract (not SCHEMA redeclaration). For a v0.5 store, also report that root conversion and filename renames remain on **migrate** Checklist D.

## Fail closed

Missing Atlas id/root → do not install. Wrong store guessed → do not install. Unmigrated `todo/` only or kebab-id store → do not install; use **migrate**.
