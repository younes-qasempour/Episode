# Agent Workflow

Use this lifecycle for every Codex, Antigravity, or other coding-agent task.

## 1. Read context

Read the sequence in root `AGENTS.md`, the relevant feature document, the last
agent changelog entries, current Git status, and recent diff. Do not rely on
chat history as project memory.

## 2. Inspect relevant code

Locate:

- an existing similar implementation;
- the entry point and data/state owner;
- constructor callbacks and public interfaces;
- model, repository, service, and theme dependencies;
- tests and documentation;
- overlapping uncommitted work.

Never assume a feature is missing before searching for it.

## 3. Create an implementation brief

Privately summarize:

- requested behavior;
- affected layers and likely files;
- backward-compatibility/data risks;
- known unknowns and explicit assumptions;
- validation plan.

Use the evidence labels in `docs/README.md`.

## 4. Plan incrementally

Prefer the smallest coherent change. Do not start with a broad refactor or
parallel architecture. If a rewrite is necessary, explain why incremental
work cannot satisfy the task before editing.

## 5. Implement

- Follow callback-driven state, repository boundaries, constructor injection,
  `MediaItem`, and `AppTheme` conventions unless the task changes them.
- Keep business/data access out of widgets when existing lower layers own it.
- Reuse components and do not edit generated files.
- Preserve stored data and public interfaces unless explicitly allowed.
- Keep secrets and environment-specific credentials out of Git.

## 6. Validate

Run the narrowest tests during development, then:

```bash
dart format lib test
flutter analyze
flutter test
```

Run a relevant build for platform/configuration changes. If dependency or
environment failures block validation, record the exact command, exit result,
and whether the failure predates the task.

## 7. Review the diff

Check for:

- unrelated modifications or formatting churn;
- debug output and secrets;
- hard-coded values where an abstraction exists;
- duplicated models, clients, repositories, widgets, or theme tokens;
- unhandled loading, empty, and error states;
- missing tests and backward-compatibility coverage;
- accidental generated-file edits;
- documentation drift.

## 8. Update documentation

Update only affected documents:

- `CURRENT_STATE.md` for feature completion, placeholder/integration status, or
  major blocker changes;
- `ARCHITECTURE.md` for new layers, data flow, state management, routing, or
  persistence changes;
- `CODEBASE_MAP.md` for important directory/file responsibility changes;
- feature docs for behavior, route, state/data flow, API, or limitation
  changes;
- `DECISIONS.md` for meaningful technical choices or intentional convention
  changes;
- `KNOWN_ISSUES.md` when verified issues are added, fixed, or clarified.

Documentation belongs in the same change as the code.

## 9. Record the change

Add an entry to `CHANGELOG_AGENT.md` with date, task, agent/tool if known,
summary, files, validation, updated docs, and unresolved issues.

## 10. Handoff

Use `templates/AGENT_HANDOFF_TEMPLATE.md`. Include what/why, files, decisions,
assumptions, exact commands/results, remaining issues, and the next
recommendation.

## Multi-agent protocol

1. Treat repository documentation as shared memory.
2. Write architectural knowledge and decisions into the repository.
3. Inspect Git status/diff before starting and before handoff.
4. Use separate branches/worktrees for parallel changes.
5. Coordinate shared interfaces through tests and documentation.
6. Do not overwrite unfinished work without understanding it.
7. Repair stale documentation discovered in task scope.

## Git

Do not commit, push, branch, or open a pull request unless authorized. When
authorized, prefer focused `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, or
`chore:` commits. Keep directly related code, tests, and documentation together.
