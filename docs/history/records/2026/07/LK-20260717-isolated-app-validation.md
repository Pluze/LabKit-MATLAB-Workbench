# App validation no longer relies on sibling App paths

```labkit-change
schema: 2
id: LK-20260717-isolated-app-validation
date: 2026-07-17
sequence: 128
type: test
compatibility: compatible
scope: Public App path isolation
scope: Changed-file validation routing
scope: GUI CI evaluation
```

## Context

The ordinary public test setup adds every App entry folder so family and
cross-App contract suites can run efficiently. That broad path can conceal an
accidental dependency on a sibling App package. Static source scans rejected
direct sibling calls, and individual Gait/private launch tests used isolated
paths, but there was no uniform executable contract for every public App or
automatic changed-file route to that contract.

## Decision and rationale

Keep the convenient broad path for ordinary suites, but add one fast
independent proof. For each public App, restore MATLAB's default path, add only
the repository root and the owning App root, load its complete definition,
check declared facade compatibility, and write its synthetic debug sample.
Run this contract whenever public App source changes.

Static call scanning and dynamic isolation cover different risks and remain
separate. The former identifies the forbidden source reference; the latter
proves metadata, framework requirements, and debug generation work in the
same path shape as a single-App package.

## Changes

- Added one isolated-path contract covering all 20 public Apps.
- Routed every App source change to that contract in both conservative and
  fast changed-file plans.
- Added a planner regression so future routing changes cannot silently drop
  isolation coverage.
- Documented why independent private workspaces must run their own
  compatibility checks without inheriting public App roots.
- Evaluated, but did not add, a hidden-GUI job to every pull request.

## User and developer impact

There is no App or saved-data behavior change. A new sibling package
dependency, stale facade requirement, incomplete definition, or broken debug
sample now fails in a focused non-GUI contract instead of passing because all
Apps happened to be on the developer's MATLAB path.

## Compatibility and migration

No migration is required. Existing test commands remain unchanged; the
changed-file planner adds the focused isolation selection automatically.

## Validation

The all-App isolation contract completed in about 14 seconds locally. Existing
changed-file evidence measured representative hidden image workflows at about
18 seconds each and a Gait hidden launch at about 30 seconds, before MATLAB
startup and license acquisition. Since those synthetic GUI checks still do not
prove native dialogs, pointer feel, or visual quality, ordinary CI keeps the
fast non-GUI contract while App-specific GUI checks remain changed-file,
scheduled, manual, and release validation.

The private workspace's independent suite passes after removing public App
roots from its runner path.

## Evidence

- [Testing and validation](../../../../development/maintain-and-release/testing.md)
- [Architecture](../../../../development/build-apps/architecture.md)
- [App development](../../../../development/build-apps/app-development.md)

## Known limitations and follow-up

MATLAB process-global function caches cannot replace package-boundary source
review, so the static sibling-call guard remains required. Hidden GUI tests
remain bounded semantic checks rather than substitutes for manual interaction
and visual assessment.
