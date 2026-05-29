# Agent Instructions

This repository provides package-backed MATLAB app entry points for Gamry electrochemistry analysis workflows.

## Read Order

Before editing:

1. `README.md`
2. `AGENTS.md`
3. The source, test, or doc files directly involved in the task

Also read these only when relevant:

- `docs/architecture.md` for package boundaries or entrypoint work
- `docs/data_model.md` for item/result/session schema work
- `docs/file_format_notes.md` for parser work
- `docs/validation_protocol.md` for test or validation work
- `docs/refactor_history.md` for historical migration context

## Core Rule

Preserve behavior unless the user explicitly asks for a behavior change.

The desired architecture is:

```text
apps/ experiment apps
    call reusable +gamrywb DTA and GUI APIs
    own experiment-specific scientific logic, parameters, plots, and exports

+gamrywb reusable library
    Gamry/DTA loading and data APIs
    scientific-app base GUI APIs
    small shared utilities only when they are genuinely cross-cutting
```

Do not add new experiment-specific app logic to the reusable `+gamrywb` library. Existing `+gamrywb/+analysis`, `+gamrywb/+plot`, and app-specific export helpers are transitional unless they are genuinely broad, low-level utilities. When touching them, consider whether the logic should move into the relevant app instead of becoming a deeper abstraction.

Do not change:

- scientific formulas, thresholds, integration rules, or result definitions
- parser behavior or pulse detection behavior
- CSV column names or exported table structure
- GUI layout, plot labels, markers, axes, or visual behavior
- current app entrypoint compatibility

Default principle:

```text
same results, cleaner code, clearer boundaries
```

## Allowed Work

- Move duplicated helper logic into `+gamrywb` package functions.
- Update app entry points to call package helpers when behavior is preserved.
- Move app-specific implementations and experiment-specific scientific workflow code out of `+gamrywb` when doing so preserves behavior.
- Add or update tests for pure functions and app entry points.
- Update documentation to reflect current behavior.
- Improve app entrypoint clarity without reintroducing root-level legacy command wrappers.

## Forbidden Without Explicit Approval

- Do not rewrite all GUIs in one pass.
- Do not start or redesign the unified workbench GUI.
- Do not reintroduce root-level legacy command wrappers.
- Do not convert struct models to MATLAB classes prematurely.
- Do not migrate code to Python or another language.
- Do not commit generated logs, `.DS_Store`, local experiment output, temporary exports, or unrelated files.

## Tests

Run after executable MATLAB changes:

```bash
scripts/run_matlab_tests.sh
```

Run optional GUI checks when GUI entry points, wrappers, layout initialization, callback wiring, or GUI test support changes:

```bash
scripts/run_matlab_tests.sh --gui
```

If MATLAB cannot run, report the blocker and do not claim tests passed.

Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Git Workflow

1. Inspect status before editing.
2. Keep each commit small and logical.
3. Do not mix unrelated functional, documentation, formatting, or test changes.
4. Run relevant tests or explain why they were not run.
5. Review the diff for unrelated changes.
6. Commit with a concise message.
7. Do not force-push unless explicitly approved.

When MATLAB source, tests, fixtures, or package structure change, update the matching current docs:

- `README.md` for user-facing commands or current status
- `CHANGELOG.md` for release-facing changes
- `docs/architecture.md` for package boundaries or entrypoint roles
- `docs/data_model.md` for schemas
- `docs/file_format_notes.md` for parser assumptions
- `docs/validation_protocol.md` for validation coverage
- `docs/refactor_history.md` only for historical context

## Handoff

Report:

- changed files
- what was intentionally not changed
- test commands and results
- blockers or unverified behavior
- recommended next step
