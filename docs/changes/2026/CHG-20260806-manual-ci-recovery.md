# Continuous Integration has two validation modes and a recovery trigger

```labkit-change
id: CHG-20260806-manual-ci-recovery
date: 2026-08-06
type: ci
compatibility: compatible
component: repository
```

## Why

Pull requests need one complete cross-platform claim. Once strict branch protection accepts that claim, the exact `main` commit needs only a lightweight integration record and a fresh documentation deployment. GitHub Actions can also fail to create or recover an event-driven required check.

### Accepted choice

Use two validation modes: complete validation for pull requests, and a lightweight exact-commit policy record after protected integration to `main`. A manual dispatch is only another trigger for complete validation. It shares the pull-request jobs and gate while using distinct concurrency state, so it does not create a third validation scope or depend on a damaged run record.

## What changed

- Pull requests always run policy, the full MATLAB platform matrix, and the deterministic documentation check.
- Protected `main` pushes run only the exact-commit policy record and aggregate gate.
- Manual dispatch reuses the full validation jobs with one concurrency group per recovery run.
- Every accepted `main` push rebuilds and deploys Documentation Pages.
- The unused changed-path classifier and its conditional routing are retired.

## Impact

No App behavior, scientific data, projects, results, or public APIs change. Maintainers get one predictable pull-request claim, documentation that follows every accepted change, and recovery without a content-free source commit.

## Compatibility and limits

Full pull-request evidence and lightweight protected-main evidence remain compatible with the existing required `CI Gate`. Existing branches require no migration.

### Remaining limits

The GitHub Actions service must be operational enough to accept a manual dispatch. This recovery path cannot replace developer-led interactive App validation or a successful required check.
