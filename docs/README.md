# Episode Documentation

This directory is Episode's persistent project memory. Claims are based on the
repository as verified through **2026-08-12**; uncertainty is labeled
explicitly.

## Start here

- [Project overview](PROJECT_OVERVIEW.md) — product purpose and visible flows
- [Current state](CURRENT_STATE.md) — implemented, partial, blocked, and tested
- [Architecture](ARCHITECTURE.md) — layers, state, navigation, and data flow
- [Codebase map](CODEBASE_MAP.md) — where code lives and where changes start
- [Development guide](DEVELOPMENT_GUIDE.md) — setup and coding conventions
- [Design system](DESIGN_SYSTEM.md) — implemented UI patterns and gaps
- [Data and API](DATA_AND_API.md) — local storage and remote endpoints
- [Testing guide](TESTING_GUIDE.md) — test structure and expectations

- [Native backup schema](BACKUP_SCHEMA.md) - portable format, integrity, and migrations

## Agent coordination

- [Agent workflow](AGENT_WORKFLOW.md)
- [Task board](TASK_BOARD.md)
- [Decisions](DECISIONS.md)
- [Known issues](KNOWN_ISSUES.md)
- [Glossary](GLOSSARY.md)
- [Agent changelog](CHANGELOG_AGENT.md)
- [Feature index](features/README.md)
- [Templates](templates/)

`DESIGN.md` at the repository root is the original visual specification.
[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) distinguishes that intent from what the
application currently implements.

## Evidence labels

- **Unknown:** the repository provides no evidence.
- **Needs confirmation:** a product or technical choice requires owner input.
- **Inferred from current implementation:** supported by code structure, but
  not explicitly documented as intent.
- **Planned but not implemented:** written intent exists without implementation.
- **Partially implemented:** some behavior exists, but the visible flow is
  incomplete.
