# Headless validation follows current documentation and App contracts

```labkit-change
schema: 2
id: LK-20260719-headless-validation-repair
date: 2026-07-19
sequence: 137
type: fix
compatibility: behavior-preserving
component: `labkit_TTestWizard_app` | `1.0.0 -> 1.0.1`
scope: Continuous integration
scope: Documentation validation
scope: Statistics
```

## Context

The first main-branch validation after the path-derived documentation change
still asserted several retired documentation paths. The same run exposed
T-Test Wizard code-quality findings and a framework GUI test file that had
grown beyond its review budget.

## Decision and rationale

Align validation with the current path-owned documentation structure and keep
Runtime-owned empty session buckets out of App factories. Resolve the static
analysis findings without changing calculations, export values, or visible
workflow behavior. Split the workspace-specific GUI coverage by capability so
each test file remains focused.

## Changes

- Updated documentation guardrails to use the current testing, Runtime, and
  complete-App guide paths.
- Removed an empty `view` placeholder that Runtime already supplies.
- Replaced dynamic array growth in group-label and group-reassignment helpers
  with bounded collection.
- Centralized the box-plot label and documented the plot-jitter and
  significance-display constants.
- Split workspace-page and dynamic-table GUI coverage into its own focused
  test file.

## User and data impact

T-Test Wizard calculations, project data, CSV values, plots, and workflows are
unchanged. The App version advances to 1.0.1 to record the internal validation
repair.

## Compatibility and migration

Existing version-1 projects remain compatible and require no data migration.
Runtime continues to provide `selection`, `workflow`, `view`, and `cache` in
the final session state.

## Validation

Focused contract and T-Test core tests cover the original headless failures.
Hidden GUI tests cover the T-Test workflow and the extracted Runtime workspace
coverage. Documentation rendering and changed-file gates validate the final
main-branch handoff.

## Evidence

- [T-Test Wizard](../../../../apps/statistics/ttest-wizard/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)
- [Testing LabKit](../../../../development/maintain-and-release/testing.md)

## Known limitations and follow-up

Interactive native-dialog behavior remains a developer-led manual validation
responsibility; hidden GUI automation does not replace it.
