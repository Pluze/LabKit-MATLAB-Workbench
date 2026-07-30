---
name: labkit-test-planner
description: "Use for validation planning, MATLAB test execution, pre-commit checks, CI scope, GUI checks, fixtures, or test-catalog changes."
---

# LabKit Test Planner

## Read

Read `AGENTS.md`, the affected source/specification, and
`docs/development/maintain-and-release/testing.md`. Read the catalog source
only when changing catalog behavior or diagnosing its output.

## Plan From Production Ownership

Tests are owner-first behavioral specifications beneath `tests/specs/`; no
caller infers test paths, stage tags, suite roots, ranges, or runner options.

1. Begin with `labkittest.explain(SOURCE_FILE)` for a production change.
2. Add evidence with `labkittest.createSpec(SOURCE_FILE, Name=..., Reason=...)`.
   Reason starts with `Regression`, `Invariant`, or `Compatibility`; specify
   `Contract` only when `explain` reports multiple author-owned boundaries.
3. Iterate with `labkittest.run(Owner=..., Contract=...)`, or use
   `labkittest.run(File=...)` for the catalog's complete bounded closure.
4. Use `buildtool changedFast` once when `develop` or a `hotfix/*` branch is
   ready for final PR review.

`createSpec` deliberately fails for framework-provided conformance and for
ambiguous contracts. These are authoring decisions, not a reason to invent a
test wrapper or folder. A missing-contract or zero-selection result is a
failure to supply evidence, never a passing test result.

For focused MATLAB execution, add `tests` to the path and call
`labkittest.run`; `buildtool test --tasks` is not a catalog selector. Every
changed `projectSpec.m` must explain to nonempty App-owned `persistence`
evidence even when an end-to-end save/restore workflow also passes.

## Choose Evidence

Use the smallest behavior that proves the change:

1. pure calculation, parser, result schema, or project migration;
2. direct presenter, renderer, callback, or state transition;
3. one hidden-GUI structural proof when declared layout/wiring is itself the
   behavior;
4. one bounded App workflow only when lower layers cannot prove the contract;
5. `changedFast`, then CI, only at final integration.

One GUI identity can be costly despite reporting one test. Diagnose its failed
helper or callback directly before rerunning the workflow. Keep broad runs
single-process unless an end-to-end benchmark shows a material net gain after
startup, licensing, reporting, progress, and failure-diagnosis costs.

## Profiles and Claims

- `buildtool headless` runs every `Env:headless` identity.
- `buildtool gui` runs every `Env:hidden-gui` identity with hidden figures.
- `buildtool isolated` runs every `Env:path-isolated` identity.
- `buildtool coverage` adds Cobertura XML and HTML coverage to headless.
- `buildtool changedFast` maps local Git paths to exact evidence closures. A
  framework, build, or policy path selects explicit system evidence;
  documentation is owned by `docsCheck`; an unknown path fails planning until
  it has a declared validation owner or explicit ignore reason.
- Hidden GUI proves declared structural wiring, not native dialogs, visual
  quality, pointer feel, real-data suitability, or scientific validity.

Use host permission for every MATLAB invocation. Keep GUI runs hidden and do
not automate manual native-dialog or pointer workflows in `-batch`. Use only
minimal synthetic fixtures; never track sensitive lab data.

When a legitimate all-App or GUI run can outlive one tool request, start one
hidden MATLAB process with durable redirected output, then poll its progress
artifact or log. A client timeout is not test evidence and is not a MATLAB
failure; record the executor's terminal result.

## Report

Report the exact owner/contract or profile command, selected identity count,
pass/fail result, artifact folder, GUI/manual boundary, and why any broader
gate is intentionally deferred. For final integration, report `changedFast`
and the CI state for the exact pushed commit.
