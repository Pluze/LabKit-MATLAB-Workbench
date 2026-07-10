# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or general
roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns active migration debt facts, reopen
triggers, and executable migration routes.

## How To Use This File

Use this file only for active migration debt, runner complexity, helper
structure, app-owned package cleanup, framework hook extraction, or an
explicitly requested executable migration route.

Before executing or adding a route:

1. Verify current facts with source scans; snapshots drift.
2. Preserve app-first ownership: workflow stays in apps, reusable mechanics
   move to `+labkit` only after the boundary test is clear.
3. Prefer behavior-backed refactors. A smaller file is not progress unless
   responsibilities become clearer and the real GUI/app path uses the helper.
4. Update this file only when migration debt is added, reduced, retired, or
   reprioritized.

When a route completes, shrink this file. Completed work should become source,
tests, docs, or guardrails, not permanent roadmap prose.

## Current Debt Snapshot

Last audited: 2026-07-10.

Active migration debt:

```text
none
```

Current facts from a lightweight source scan:

- Package-root app `run.m` orchestration and `+ui/runApp.m` lifecycle adapters
  are retired.
- Workflow-first public apps use `definition.m`, `definitionActions.m`,
  `+appLifecycle/createInitialState.m`,
  `+userInterface/buildWorkbenchLayout.m`, and app-owned workflow packages such
  as `+appState`, `+sourceFiles`, `+analysisRun`, `+cropGeometry`, and
  `+resultFiles`.
- Transitional app buckets such as `+state`, `+actions`, `+ui`, `+view`,
  `+ops`, `+io`, and `+export` should not be reintroduced.
- Source inventory at this audit: 920 tracked MATLAB files across `apps/`,
  `+labkit/`, and `tests/`; the largest app file is 644 lines, the largest
  `+labkit` file is 636 lines, and the largest test file is 650 lines.
- Current hotspots are watchlist facts, not active migration routes by
  themselves. Open a route only when the next change would add unrelated
  behavior or a concrete responsibility split is found.

## Reopen Triggers

Open a new active route here only when current scans expose concrete debt:

- a package-root app `run.m` or `+ui/runApp.m` reappears
- a new app uses broad technical buckets such as `+actions`, `+state`, `+ui`,
  `+view`, `+ops`, `+io`, or `+export`
- a substantive change would add unrelated behavior to a budget-watchlist
  action table without a responsibility audit
- helper-quality audit reports new `inline-or-merge-candidate` rows after
  excluding valid contracts such as app entrypoints, `requirements.m`,
  `version.m`, workflow layout builders, state factories, input policies,
  framework adapters, and action-driven side-effect boundaries
- a new app entry point appears without dedicated GUI coverage
- hidden workflow validation needs a new app-neutral driver operation or
  app-owned test hook to avoid OS/modal dialogs
- current JUnit timing or profiler evidence identifies a new test-performance
  hotspot whose fix would change runner behavior, validation policy, or
  app/workflow coverage
- migration exposes package-boundary drift that cannot be fixed locally without
  a new `+labkit` API decision

## Compatibility Queue

The DTA facade intentionally keeps legacy bridge fields beside canonical
unit-explicit fields. This is compatibility debt, not current cleanup debt.

Do not remove fields such as chrono `t`, `Vf`, `Im`, `alignTime`, `tAligned`,
or EIS `Pt`, `Freq`, `Zreal`, `Zimag`, `negZimag` during ordinary runner
cleanup. A removal requires an explicit DTA major-version route after
electrochem apps and tests have moved to canonical fields.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral
foundation with UI, image, DTA, RHS, thermal, and biosignal facades.
App-specific calculations, summaries, plots, exports, workflow wording, file
conventions, and result schemas stay under the owning app tree.

Migration progress means:

- a responsibility boundary becomes clearer
- deterministic behavior becomes directly testable
- the real GUI or app path uses the extracted helper
- duplicate app-neutral mechanics are removed from apps
- total workflow cognitive load falls

Migration is not progress when it only moves a large block, creates tiny
cosmetic helpers, hides app workflow behind generic names, adds noisy
guardrails, or adds docs without retiring stale debt or clarifying an active
contract.

Use `labkit-boundary-guard` before promoting behavior to `+labkit`. Use
`labkit-test-planner` for validation routing and `docs/testing.md` for exact
commands.
