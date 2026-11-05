# atlas-tasks

atlas-tasks adds distributed task tracking to Atlas, with task bodies alongside related knowledge and indexes that point to tasks and task lists.

## Why / what this is not

Use atlas-tasks to add, update, complete, and recall tasks on an Atlas the operator names. It extends Atlas's core `task` pages; it does not replace Governor tasks or APM HITL queues, and it does not write to an unnamed or implicit Atlas.

## Capabilities

- Maintain `tasks/index.md` as each Atlas's root task list, with loose tasks and pointers to named task lists.
- Keep task bodies beside related knowledge; core `task` pages and task-list pages act as pointers.
- Create and maintain task lists with `type: task-list` pages and membership pointers.
- Record dependencies with `relates_to` edges and derive a task's blocked state from open or in-progress dependency targets. Cross-Atlas references can name remote tasks; reverse `blocks` edges are written only within the same Atlas.
- Install the `atlas-tasks` schema overlay on an operator-named Atlas.

## Install

```bash
apm marketplace add sergio-sisternes-epam/atlas-marketplace --name atlas
apm install atlas-tasks@atlas
```

Installing the APM package does not mount its overlay. Mount it separately on the Atlas the operator chooses:

```bash
python3 <atlas-skill>/scripts/atlas.py schema install \
  <atlas-tasks-package>/contributions/atlas-tasks \
  --root <your-atlas-root>
python3 <atlas-skill>/scripts/atlas.py compile --root <your-atlas-root>
```

## Use

1. Name the target Atlas and run the skill path `mount-overlay`.
2. Run `add` with a related node path and task title.
3. Confirm that `tasks/index.md` contains the new task pointer and `atlas compile` succeeds.

## Prerequisites

The Atlas CLI must be available through the `atlas` skill or `scripts/atlas.py`. A target Atlas must be named before task operations or overlay writes.

## Related

- [Atlas marketplace](https://github.com/sergio-sisternes-epam/atlas-marketplace) — package catalog.
- [`atlas`](https://github.com/sergio-sisternes-epam/atlas) — core Atlas skill and CLI.
- [`contributions/atlas-tasks/README.md`](contributions/atlas-tasks/README.md) — normative overlay contract.
- [`SKILL.md`](SKILL.md) — task operations and runtime rules.

## Migrate / upgrade

For legacy `todo/` stores, `depends_on`, older task identifiers, or older filename layouts, follow the [`migrate` path](references/paths/migrate.md). Release history is in [`CHANGELOG.md`](CHANGELOG.md).

## Validation

Run the package smokes from the repository root:

```bash
ATLAS_CLI=<atlas-skill>/scripts/atlas.py bash scripts/smoke-check.sh .
bash scripts/public-hygiene-scan.sh --all
```

`ATLAS_CLI` is optional when the `atlas` skill is installed beside this package. The SCHEMA 2.0 smokes require the Python `jsonschema` package.

## License

Apache License 2.0 — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
