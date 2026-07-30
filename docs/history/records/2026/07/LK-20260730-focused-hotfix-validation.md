# Focused hotfix validation

```labkit-change
id: LK-20260730-focused-hotfix-validation
date: 2026-07-30
sequence: 164
type: ci
compatibility: compatible
scope: Explicit bounded CI route for small product hotfixes
```

## Context

Every executable-source pull request previously scheduled the complete
cross-platform MATLAB matrix. That remains appropriate for ordinary
development and compatibility-sensitive hotfixes, but it repeated all seven
platform shards for small repairs whose repository-owned changed-file closure
already names the complete relevant evidence.

## Decision and rationale

Reserve `hotfix/focused/<name>` for an explicit bounded-validation claim. An
eligible pull request runs `changedFast` in one clean latest-MATLAB Linux
environment and still runs the documentation check when authored docs change.
Ordinary hotfixes retain the full matrix.

The focused route cannot include CI workflow or helper changes, Build logic,
test framework/catalog code, maintainer tools, resources, or dependency
governance. Any such path automatically restores the full matrix. This keeps
the branch name from becoming an unrestricted validation bypass.

## Changes

- Added a focused-hotfix result to CI path classification.
- Added one clean-runtime `changedFast` job and made `CI Gate` require it when
  selected.
- Kept full-matrix fallback for ordinary hotfixes and ineligible focused
  diffs.
- Added classifier and repository-architecture regression coverage.

## User and data impact

Small product repairs can reach protected `main` without paying for unrelated
platform sessions while still producing hosted evidence for their exact
changed-file closure. Product behavior, data, and scientific calculations are
unchanged.

## Compatibility and migration

Existing `develop` and `hotfix/<name>` workflows are unchanged. Maintainers
choose the focused route only by using the reserved nested branch namespace.

## Validation

Python specifications cover eligible, ordinary, and forbidden focused
classifications. Repository architecture specifications cover the focused job
and aggregate gate. The governance change itself receives the complete matrix
before the focused route is used.

## Evidence

The classifier, CI workflow, Python tests, repository architecture
specifications, testing manual, and this record are the reviewable evidence.

## Known limitations and follow-up

Focused validation is intentionally not a cross-platform compatibility claim.
Reviewers must use an ordinary hotfix whenever the repair depends on native
dialogs, filesystems, graphics, packaging, external processes, or
release-specific behavior.
