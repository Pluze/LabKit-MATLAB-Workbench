# Release validation includes Base MATLAB compatibility

```labkit-change
id: LK-20260717-release-validation-hardening
date: 2026-07-17
sequence: 129
type: ci
compatibility: compatible
scope: scheduled and release-candidate validation
```

## Context

LabKit already exposed `buildtool baseMatlab`, but GitHub Actions did not run
the broad MATLAB product-ownership analysis. A release candidate could
therefore pass headless, coverage, and GUI jobs while the explicit Base MATLAB
compatibility gate remained a local-only check.

## Decision and rationale

Run the existing public `baseMatlab` task in scheduled and manually dispatched
workflows, and require it before a validated release tag can be created.
Ordinary pull requests and main pushes retain the smaller headless gate because
the static call scan and representative fallback workflows already run there.

## Changes

- Added a dedicated Base MATLAB compatibility job with JUnit, active-test, log,
  and artifact reporting.
- Added that job to the release-test dependency gate.
- Corrected the CI contract test so it discovers actual `tasks:` values and
  checks them against the executable build-task catalog.
- Updated artifact upload jobs to the current Node.js 24 action generation.

## User and data impact

No App behavior or saved data changes. A release tag is now blocked when
MATLAB resolves production source to an undeclared MathWorks product.

## Compatibility and migration

The public `buildtool baseMatlab` command is unchanged. GitHub-hosted runners
meet the action runtime requirement; no self-hosted runner migration is
introduced.

## Validation

The CI policy contract verifies job scope, public-task ownership, diagnostics,
timeouts, parent checkout depth, and release-gate dependencies. The Base MATLAB
task remains covered by its own dependency guardrail.

## Evidence

`.github/workflows/matlab-tests.yml` is the executable release gate;
`tests/cases/contract/project/ci/CiValidationPolicyGuardrailTest.m` protects
its routing and dependency structure.

## Known limitations and follow-up

The product-ownership analysis depends on MATLAB's dependency report and cannot
replace manual scientific or interactive App validation.
