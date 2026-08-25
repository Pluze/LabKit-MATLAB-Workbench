# Release validation includes Base MATLAB compatibility

```labkit-change
id: CHG-20260717-release-validation-hardening
date: 2026-07-17
type: ci
compatibility: compatible
component: repository
```

## Why

LabKit already exposed `buildtool baseMatlab`, but GitHub Actions did not run the broad MATLAB product-ownership analysis. A release candidate could therefore pass headless, coverage, and GUI jobs while the explicit Base MATLAB compatibility gate remained a local-only check.

### Accepted choice

Run the existing public `baseMatlab` task in scheduled and manually dispatched workflows, and require it before a validated release tag can be created. Ordinary pull requests and main pushes retain the smaller headless gate because the static call scan and representative fallback workflows already run there.

## What changed

- Added a dedicated Base MATLAB compatibility job with JUnit, active-test, log, and artifact reporting.
- Added that job to the release-test dependency gate.
- Corrected the CI contract test so it discovers actual `tasks:` values and checks them against the executable build-task catalog.
- Updated artifact upload jobs to the current Node.js 24 action generation.

## Impact

No App behavior or saved data changes. A release tag is now blocked when MATLAB resolves production source to an undeclared MathWorks product.

## Compatibility and limits

The public `buildtool baseMatlab` command is unchanged. GitHub-hosted runners meet the action runtime requirement; no self-hosted runner migration is introduced.

### Remaining limits

The product-ownership analysis depends on MATLAB's dependency report and cannot replace manual scientific or interactive App validation.
