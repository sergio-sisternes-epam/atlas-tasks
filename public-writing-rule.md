---
type: decision
title: "Public writing rule for this Atlas"
created: "2026-10-09"
description: "Rules every agent or person must follow when writing to this public atlas branch."
status: accepted
---

## Decision

This branch is public and permanent. Every commit is visible forever; a leak can only be fixed by a history rewrite, which branch protection blocks. Everyone writing here, human or agent, follows these rules.

## Rules

- Write in a neutral, public-grade voice.
- Record design decisions, rationale, pins, recipes and outcomes, not operational chatter.
- Refer to people and agents by role only ("the maintainer", "the package steward", "a consumer Atlas", "the operator"). Never use personal names, private agent or bot names, or personas.
- Never include:
  - private hostnames or domains;
  - absolute machine paths (use placeholders such as `<atlas-root>`);
  - SSH remotes;
  - credential or vault references;
  - session or conversation ids;
  - email addresses other than GitHub noreply addresses;
  - personal or family details.
- Use neutral synthetic examples (for example, a software-release plan) instead of real personal data.
- Link to pull requests or issues only when they are in this public repository.
- Commits use a GitHub noreply author and committer, with plain messages.
- All changes reach `atlas` by pull request and must pass the `Public hygiene scan` check.

## Consequences

Pages that break these rules are rewritten before they merge. If you are unsure, leave the detail out.
