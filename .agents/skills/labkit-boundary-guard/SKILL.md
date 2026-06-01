---
name: labkit-boundary-guard
description: "Use for LabKit refactors, extraction, public API additions, package-boundary decisions, helper moves, creating packages, touching +labkit, or changing app-vs-library ownership. Do not use for simple human-doc copyedits with no architecture impact."
---

# LabKit Boundary Guard

## Goal

Preserve LabKit's app-first architecture:

- apps own experiment-specific workflow
- `+labkit` owns small, stable UI/DTA/biosignal facades
- no public helper-dump packages

## Required Read Order

1. `AGENTS.md`
2. nearest scoped `AGENTS.md`
3. `docs/architecture.md`
4. relevant component doc: `docs/apps.md`, `docs/ui.md`, `docs/dta.md`, or `docs/biosignal.md`
5. directly touched source and tests

## Boundary Decision

Before moving code into `+labkit`, prove that the helper:

- can be named without experiment-specific vocabulary
- does not encode domain units, thresholds, result columns, plot wording, or export schemas
- does not read or mutate app state
- is independently testable
- is used by at least two real apps or clearly belongs to a broad facade
- reduces duplication without increasing public API confusion

If this is not proven, keep the code app-local.

## Validation

Always run or recommend:

```bash
scripts/run_matlab_tests.sh --suite project
```

Add focused suites by touched boundary:

```bash
scripts/run_matlab_tests.sh --suite labkit/dta --suite apps/electrochem
scripts/run_matlab_tests.sh --suite labkit/biosignal --suite apps/wearable
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
scripts/run_matlab_tests.sh --suite apps/electrochem
```

If MATLAB is unavailable, report that clearly and do not claim tests passed.

## Handoff Requirements

Report:

- boundary decision made
- files changed
- what was intentionally not extracted or generalized
- validation commands and results
- remaining manual GUI checks
