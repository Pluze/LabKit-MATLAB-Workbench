# Documentation Guide

These docs are written for people who run, maintain, or extend LabKit. Start with the page that matches the work in front of you; you do not need to read the whole documentation set for everyday app use.

## Documentation Responsibilities

| Source | Owns |
| --- | --- |
| `../README.md` | Project overview, app launch list, and the default validation entry point. |
| `*.md` component docs | Human-readable behavior, architecture, public APIs, and maintenance contracts. |
| `testing.md` | The canonical build-task matrix, wrapper behavior, CI scope, fixture expectations, and GUI validation limits. |
| `../AGENTS.md` and scoped `AGENTS.md` files | Future execution rules for agent work, ownership red lines, and routing rules. |
| `../.agents/migration_guide.md` | Agent-facing migration debt ledger, current debt snapshot, and future debt-handling rules. |
| `../.agents/skills/` | Task procedures for boundary checks, app building, migration planning, and validation routing. |
| `../tests/integration/project/` guardrails | Automated checks that keep package boundaries, documentation ownership, debt inventory, and sample hygiene from drifting. |

## I Want To Run An App

- `../README.md`: project overview, startup command, app list, and default validation entry point.
- `apps.md`: current app families, what each app does, expected inputs, and typical outputs.

## I Maintain An App

- `apps.md`: app ownership, current app notes, and new-app checklist.
- `ui.md`: shared GUI shell, tabs, panels, axes, and reusable UI helper contracts.
- `testing.md`: focused app and GUI structural build-task commands.

## I Work On Reusable APIs

- `architecture.md`: package boundaries and the extraction rule for moving code into `+labkit`.
- `ui.md`: reusable GUI foundation.
- `dta.md`: Gamry DTA loading, parsing, session, pulse, and curve facade.
- `biosignal.md`: recording loading, signal processing, ECG detection, segments, templates, and measurements.

## I Need Validation Guidance

- `testing.md`: default and focused build tasks, GUI versus non-GUI checks, fixture expectations, and CI scope.

## Component Reference

| Doc | Use it for |
| --- | --- |
| `architecture.md` | Package boundaries, ownership rules, and extraction decisions. |
| `apps.md` | App entry points, app-family notes, and app-owned workflow guidance. |
| `ui.md` | MATLAB GUI shell and reusable UI helpers. |
| `dta.md` | DTA facade, parser assumptions, and data shapes. |
| `biosignal.md` | Biosignal facade, data shapes, and ECG workflow boundary. |
| `testing.md` | Test commands, suite layout, GUI validation limits, and fixture expectations. |
