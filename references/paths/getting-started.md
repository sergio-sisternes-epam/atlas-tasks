# Path: getting-started

Load `references/paths/activation.md` first. Card `path: getting-started`.

1. Install the APM package (root skill: `SKILL.md`, `contributions/`, `references/`, `scripts/`). Preferred pin after publish: `sergio-sisternes-epam/atlas-tasks#v0.6.1`.
2. Ask the human which Atlas to use (id or mount root). Do not guess.
3. Install the v0.6 schema before converting the root. One order:
   - Already v0.6: run **mount-overlay** on that Atlas only.
   - v0.5 (URI `task_id`, ULID-only filenames, or a document index): run **mount-overlay** first, then **migrate** Checklist D. Do not convert `tasks/index.md` to `type: task-list` before that install.
   - Older surfaces (`todo/`, `depends_on`, kebab `task_id`): run **migrate** checklists A–C. Checklist A installs the v0.6 contribution before Checklist D. Do not run Checklist D, and do not rewrite the root as `type: task-list`, until that overlay is installed.
4. Add a task near a related node with **add** (skill mints ULID + `atlas://` id and writes `tasks/<ULID>-<name>.md`; optionally pass `assignees`, `parent`, `task_list`, or dependency targets). Add a named grouping with **add** as a task list.
5. List with **list** — walk from the root task list; title + ULID; watch derived blocked when dependency targets are open.
6. Move work with **update** (`in_progress`, hierarchy, membership, rename, dependency edges) and finish with **complete**.

Stop after explaining if the human only asked how to start. Do not mount until they name an Atlas and ask to proceed.
