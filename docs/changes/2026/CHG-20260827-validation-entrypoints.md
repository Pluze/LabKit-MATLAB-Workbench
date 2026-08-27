# Validation has one local gate and one App-boundary profile

```labkit-change
id: CHG-20260827-validation-entrypoints
date: 2026-08-27
type: ci
compatibility: action-required
component: repository
supersedes: CHG-20260721-local-validation-routing
supersedes: CHG-20260827-real-workflow-test-evidence
```

## Why

Maintainers had to remember separate focused-test, code-analysis, and documentation commands even though all three were required before PR review, while bare `buildtool` selected the broad headless suite without establishing the local review claim. PR CI also regenerated headless and App-journey coverage that no reviewer consumed, and its unused manual trigger could never pass because the aggregate gate required a coverage job that ran only for pull requests. Task-branch feedback could begin expensive MATLAB work during the short interval between a branch push and creation of its PR.

The accepted choice is one default local gate, one App-boundary profile, and a second ownership check before Development Feedback starts MATLAB. Hidden-GUI identities and reset-path App isolation remain distinct environment groups inside the combined profile, so the runner preserves their execution semantics without separate public commands. Coverage reporting is retired because no maintainer consumes it and behavioral assertions already own merge evidence. The complete supported-platform matrix remains required because platform- and release-specific failures demonstrate independent value.

## What changed

Bare `buildtool` now selects `changedFast`, which composes codecheck and deterministic documentation validation with focused tests from the final task diff. The build surface contains six real entry points: `changedFast`, `headless`, `apps`, `codecheck`, `docs`, and `docsCheck`; MATLAB's native `buildtool -tasks` lists them. The new `apps` profile replaces the separate `gui`, `journeys`, and `isolated` commands by running all hidden-GUI identities and then the path-isolated group in one build. Continuous Integration retains repository policy, documentation validation, and the complete MATLAB platform matrix while removing the coverage job and unusable manual recovery trigger. Development Feedback checks again for an owning PR immediately before MATLAB setup. Coverage-only planner and runner code is removed.

## Impact

Maintainers use one local pre-PR command and one App-boundary diagnostic command, PRs avoid a repeated coverage execution, and a newly opened PR can stop task-branch feedback before its expensive phase. CI continues to prove the same headless, hidden-GUI, path-isolated, minimum-MATLAB, and current desktop-platform behavior with fewer build sessions and artifacts.

## Compatibility and limits

App behavior, scientific results, saved projects, exports, public MATLAB APIs, supported platforms, test identities, and environment tags are unchanged. Maintainers must replace `buildtool gui`, `journeys`, or `isolated` with `buildtool apps`; there is no replacement coverage report because the unconsumed reporting subsystem is retired. Native dialogs, pointer feel, visual design, real-data suitability, and scientific interpretation remain manual validation boundaries.
