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
- UI apps should use the layered `labkit.ui.app/view/tool/diag` facades; the older flat helper surface has been removed

## Required Read Order

Start with a quick pass:

1. `AGENTS.md`
2. nearest scoped `AGENTS.md`
3. directly touched source and tests

Use a deep pass only when the boundary decision is not already obvious from
the touched files:

- read `docs/architecture.md` for public package surfaces, allowed debt, or
  app-vs-library ownership changes
- read the relevant component doc only for the touched facade:
  `docs/apps.md`, `docs/ui.md`, `docs/dta.md`, or `docs/biosignal.md`

## Boundary Decision

Before moving code into `+labkit`, prove that the helper:

- can be named without experiment-specific vocabulary
- does not encode domain units, thresholds, result columns, plot wording, or export schemas
- does not read or mutate app state
- is independently testable
- is used by at least two real apps or clearly belongs to a broad facade
- reduces duplication without increasing public API confusion

If this is not proven, keep the code app-local.

For UI boundary work, prefer `labkit.ui.app.createShell`, `labkit.ui.app.dispatchRequest`, `labkit.ui.diag.createContext`, `labkit.ui.tool.createRuntime`, and the unified `labkit.ui.view.section/form/panel/axes/draw/update/place` facade. Keep control micro-helpers and one-off component builders private unless they are a deliberate public facade addition.

## Validation

Run or recommend project guardrails for package-boundary and public-surface
changes. Add focused DTA, biosignal, UI, or app-family validation when that
boundary is touched, and use `docs/testing.md` for exact task names and
pairings.

If MATLAB is unavailable, report that clearly and do not claim tests passed.

## Handoff Requirements

Report:

- boundary decision made
- files changed
- what was intentionally not extracted or generalized
- validation commands and results
- remaining manual GUI checks
