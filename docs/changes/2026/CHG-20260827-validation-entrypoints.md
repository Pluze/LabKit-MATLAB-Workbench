# Validation has one local gate and no unused PR coverage job

```labkit-change
id: CHG-20260827-validation-entrypoints
date: 2026-08-27
type: ci
compatibility: compatible
component: repository
supersedes: CHG-20260721-local-validation-routing
supersedes: CHG-20260827-real-workflow-test-evidence
```

## Why

Maintainers had to remember separate focused-test, code-analysis, and documentation commands even though all three were required before PR review, while bare `buildtool` selected the broad headless suite without establishing the local review claim. PR CI also regenerated headless and App-journey coverage that no reviewer consumed, and its unused manual trigger could never pass because the aggregate gate required a coverage job that ran only for pull requests. Task-branch feedback could begin expensive MATLAB work during the short interval between a branch push and creation of its PR.

The accepted choice is one default local gate, required PR behavior evidence without duplicate coverage measurement, and a second ownership check before Development Feedback starts MATLAB. Coverage remains available on demand because it is useful for investigating omissions, but an unreviewed report is not merge evidence. The complete supported-platform matrix remains required because platform- and release-specific failures demonstrate independent value.

## What changed

Bare `buildtool` now selects `changedFast`, which composes codecheck and deterministic documentation validation with focused tests from the final task diff. Continuous Integration retains repository policy, documentation validation, and the complete MATLAB platform matrix while removing the per-PR coverage job and unusable manual recovery trigger. Development Feedback checks again for an owning PR immediately before MATLAB setup. Specialist build tasks, including `coverage`, remain available for diagnosis and explicit reports.

## Impact

Maintainers use one local pre-PR command, PRs avoid a repeated coverage execution, and a newly opened PR can stop task-branch feedback before its expensive phase. CI continues to prove the same headless, hidden-GUI, path-isolated, minimum-MATLAB, and current desktop-platform behavior.

## Compatibility and limits

App behavior, scientific results, saved projects, exports, public MATLAB APIs, supported platforms, and test identities are unchanged. Coverage reports are no longer produced automatically for every PR; a maintainer must run `buildtool coverage` when an omission investigation needs them. Native dialogs, pointer feel, visual design, real-data suitability, and scientific interpretation remain manual validation boundaries.
