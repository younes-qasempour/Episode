# Episode Agent Guide

This file is the first source of repository guidance for humans and coding
agents. Read it before editing.

## Project identity

- **Project:** Episode
- **Type:** Flutter application
- **Current stage:** Stage-one functional prototype. Library tracking, remote
  search, item editing, local persistence, and theme switching exist; several
  profile/settings and release-readiness areas remain incomplete.
- **Purpose:** Track anime, manga, and TV series in a local library, discover
  media through Jikan and TVMaze, and update progress, status, rating, and
  synopsis data.
- **Verified platforms:** Android and web directories are present. Other
  platform targets are not in this repository.

Important terms are defined in [docs/GLOSSARY.md](docs/GLOSSARY.md). In
particular, **Library** is the locally stored collection, **Explore** is the
live-search tab, and **MediaItem** is the shared anime/manga/series model.

## Required reading order

Every agent must read, in order:

1. `AGENTS.md`
2. [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)
3. [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md)
4. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
5. [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md)
6. The relevant document under [docs/features/](docs/features/README.md)
7. [docs/DECISIONS.md](docs/DECISIONS.md)
8. [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md)

Before editing, also inspect the current Git status and recent entries in
[docs/CHANGELOG_AGENT.md](docs/CHANGELOG_AGENT.md).

## Non-negotiable agent rules

- Inspect before editing. Search for existing behavior and similar
  implementations before deciding that something is missing.
- Follow the current architecture unless the task explicitly authorizes a
  change. Prefer extending an existing abstraction to creating a parallel one.
- Do not introduce another state-management package, router, API client,
  persistence layer, theme system, or dependency-injection system without
  explicit approval.
- Do not bypass repositories by calling remote APIs from widgets.
- Keep business rules out of widgets when an existing model or repository is
  the appropriate owner.
- Reuse `MediaItem`, `MediaCard`, `AppTheme`, and existing repository/service
  seams before creating equivalents.
- Never duplicate an API entity model without documented justification.
- Never replace a dependency because another package is more popular.
- Never rewrite an entire feature without first explaining why an incremental
  change is insufficient.
- Do not silently change public constructors, callbacks, or model fields.
  Preserve compatibility unless breaking changes are explicitly allowed.
- Do not remove working code merely because a different implementation looks
  cleaner. Do not mix unrelated cleanup with feature work.
- Do not manually edit generated files, including `pubspec.lock` and Flutter
  platform registrant output. Do not delete or rewrite migration history.
- Never hard-code secrets or tokens. Use existing abstractions for URLs,
  user-visible text, colors, and dimensions where they exist.
- Do not add committed `.env` files, credentials, signing keys, or service
  configuration containing secrets.
- Keep the diff focused. Preserve other developers' uncommitted work and
  understand unfinished changes before editing overlapping files.
- Document assumptions as `Unknown`, `Needs confirmation`,
  `Inferred from current implementation`, `Planned but not implemented`, or
  `Partially implemented`.
- Distinguish failures introduced by the task from pre-existing failures.
  Never claim validation passed when it did not run successfully.
- Never mark a task complete while new analyzer or test failures remain.
- Never execute destructive commands, commit, push, create a branch, or open a
  pull request without explicit authorization.
- Update affected documentation and `docs/CHANGELOG_AGENT.md` in the same
  change as implementation work.
- Run formatting, analysis, and relevant tests before handoff. Report each
  command and its exact result.

## Source-of-truth priority

1. Explicit current task requirements
2. Existing working code and tests
3. `AGENTS.md`
4. Relevant feature documentation
5. Architecture and decision documents
6. Other repository documentation
7. Agent assumptions

When code, tests, and documentation disagree, investigate the conflict. Update
stale documentation rather than trusting either source blindly.

## Standard task lifecycle

Use [docs/AGENT_WORKFLOW.md](docs/AGENT_WORKFLOW.md) and the templates under
`docs/templates/`.

1. Read context and inspect Git state.
2. Locate entry points, similar code, interfaces, tests, and documentation.
3. Write a small internal brief and incremental plan.
4. Implement only the requested change.
5. Format, analyze, test, and inspect the final diff.
6. Update affected documentation and the agent changelog.
7. Provide a handoff using
   [docs/templates/AGENT_HANDOFF_TEMPLATE.md](docs/templates/AGENT_HANDOFF_TEMPLATE.md).

## Documentation maintenance

- Update `CURRENT_STATE.md` when a feature becomes complete, a placeholder
  becomes functional, an integration is connected, or a major blocker changes.
- Update `ARCHITECTURE.md` when a layer, data flow, state-management, routing,
  or persistence strategy changes.
- Update `CODEBASE_MAP.md` when an important directory is added, removed,
  repurposed, or gains a new entry point.
- Update the relevant feature document when behavior, routes, state/data flow,
  APIs, or limitations change.
- Update `DECISIONS.md` for meaningful technical choices and intentional
  project-wide convention changes.
- Update `KNOWN_ISSUES.md` when a verified issue is found, fixed, reprioritized,
  or given better reproduction steps.
- Update `CHANGELOG_AGENT.md` after every completed agent task.

Documentation updates belong in the same change as the code that requires
them. Important knowledge must not remain only in chat history.

## Multi-agent consistency

- Repository documentation is shared memory for Codex, Antigravity, and other
  agents.
- Record architectural decisions, completed work, and handoffs in the
  repository.
- Use separated branches or worktrees for parallel work.
- Coordinate shared interfaces through documentation and tests.
- Do not overwrite another unfinished task without understanding it.
- Repair stale documentation when discovered in task scope.

## Definition of done

A task is complete only when:

- requested behavior and acceptance criteria are satisfied;
- architecture and public interfaces remain consistent;
- relevant tests are added or updated;
- formatter, analyzer, and relevant tests were run;
- no unrelated files changed;
- affected feature/current-state/architecture documentation was updated;
- `docs/CHANGELOG_AGENT.md` contains an entry;
- exact validation results and remaining limitations appear in the handoff.

## Git guidance

Use focused commits when the user authorizes commits. Preferred prefixes are
`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, and `chore:`. Code and its
directly related documentation normally belong in the same commit.
