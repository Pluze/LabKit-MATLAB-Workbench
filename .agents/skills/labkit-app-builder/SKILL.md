---
name: labkit-app-builder
description: "Use for building or refactoring a LabKit MATLAB GUI app from legacy MATLAB scripts/functions, rough reference code, command-line/debug scripts, existing GUI code, SOPs, experiment protocols, workflow notes, or prose descriptions. Trigger when creating a new app, migrating old analysis code into apps/, translating a manual lab workflow into an interactive GUI, or deciding what legacy algorithm/science/calculation to keep while redesigning app flow around labkit.ui/dta/biosignal facades."
---

# LabKit App Builder

## Goal

Turn existing analysis code or a written lab procedure into a maintainable LabKit app without turning LabKit into a monolithic platform.

The target shape is:

- one launchable app entry point under `apps/<category>/`
- reusable UI/data boilerplate behind `labkit.ui`, `labkit.dta`, or `labkit.biosignal`
- domain formulas, plot choices, result fields, export schemas, and workflow wording owned by the app
- synthetic tests for core calculations and export contracts

## Required Read Order

1. `AGENTS.md`
2. `apps/AGENTS.md`
3. `+labkit/AGENTS.md` if any reusable helper or facade may change
4. `tests/AGENTS.md` if adding tests or fixtures
5. `docs/apps.md`, `docs/ui.md`, and the relevant facade doc
6. The legacy source, SOP text, and closest existing LabKit app

Do not copy local paths, real filenames, sample labels, subject names, timestamps, device IDs, or proprietary row values into tracked files.

## Intake Pass

Inspect the legacy code or SOP before designing. Treat legacy code as evidence, not as the desired app architecture. Build a private working map with:

- accepted inputs and file families
- user actions and order of operations
- parameters, defaults, and units
- calculations and thresholds
- plot views and annotations
- result summaries and export columns
- failure cases and failed-row behavior
- sample/demo files that must not be committed
- duplicate parser, UI, plotting, or export boilerplate

For SOP-only tasks, ask for missing scientific definitions only when they cannot be inferred safely. Do not invent formulas, thresholds, pass/fail criteria, or export schemas.

## Preserve Science, Redesign Flow

Legacy scripts often contain command-line staging, debug phases, ad hoc plotting, workspace plumbing, hard-coded paths, and run-order assumptions that were useful while developing the analysis. Do not copy that runtime flow into the app.

Extract and preserve:

- scientific assumptions and definitions
- formulas, thresholds, units, and default parameters
- signal/image/data transformations that affect results
- result fields, export columns, and status meanings that users rely on
- parser or file-format edge cases that explain real input variability

Redesign or discard:

- "run section 1, then section 2" command-line workflows
- debug-only flags, figures, pauses, printouts, and intermediate saves
- base-workspace variables, globals, `assignin`, `evalin`, and manual workspace setup
- hard-coded local paths, sample filenames, and output folders
- repeated file dialogs, one-off demo branches, and exploratory plot variants
- control flow that reflects debugging history rather than user intent

The app flow should be designed from the lab user's task: load inputs, set meaningful options, preview enough state to trust the analysis, run or refresh deterministically, inspect results, and export stable outputs.

## Triage Legacy Code

Classify every meaningful part:

- **Promote to facade** only when domain-neutral, independently testable, and useful beyond one workflow.
- **Keep app-local** for formulas, units, thresholds, labels, result fields, export tables, workflow-specific plots, and callback order.
- **Convert to app GUI** for manual steps that should become controls, previews, summaries, or export actions.
- **Convert to tests** for known numeric outcomes, parser edge cases, export column order, and previously fragile behavior.
- **Delete or ignore** one-off demo paths, local defaults, workspace plumbing, ad hoc scripts, generated outputs, sample files, and duplicated helper code already covered by LabKit facades.

When preserving legacy behavior, keep output names, column order, units, numeric tolerances, and status wording stable unless the user explicitly asks to change them.

## Design Brief Before Coding

Write a short app design brief before implementation:

```text
App name and category:
Input kind and reader/facade:
Session or app state shape:
Controls and defaults:
Core calculations:
Legacy behavior preserved:
Legacy flow intentionally discarded:
Plots and annotations:
Summary fields:
Export files and columns:
Synthetic tests:
Manual GUI checks:
Docs to update:
```

Use the closest existing app as the starting pattern, then reduce it to the actual workflow. Do not start from a large copy-only template.

## Implementation Pattern

Build the app in this order:

1. Add or update the app entry point with `labkit.ui.app.createShell`.
2. Wire file loading through the appropriate facade or app-local reader.
3. Store state in one app struct; avoid globals, base workspace state, and hidden local paths.
4. Rebuild the user workflow around stable controls, previews, summaries, and exports; do not reproduce command-line debug staging.
5. Move GUI-free calculations below the app `end` as app-local functions.
6. Add narrow internal test handlers only for app-owned GUI-free helpers or explicit structural diagnostics.
7. Render prepared data through `labkit.ui` helpers; keep analysis out of UI helpers.
8. Add export builders before CSV/PNG writing so output contracts can be tested.
9. Add focused tests with synthetic fixtures or minimal generated data.
10. Update human docs for user-facing behavior and scoped `AGENTS.md` only when rules change.

## Validation

Use `labkit-test-planner` to choose suites. Common checks:

```bash
scripts/run_matlab_tests.sh --suite project
scripts/run_matlab_tests.sh --suite apps/electrochem
scripts/run_matlab_tests.sh --suite apps/dic --gui
scripts/run_matlab_tests.sh --suite apps/image_measurement --gui
scripts/run_matlab_tests.sh --suite apps/wearable --gui
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
```

For reusable facade changes, also use `labkit-boundary-guard`.

Report automated tests separately from manual GUI validation. Do not claim full workflow validation from non-GUI tests.
