# Owner-minimal validation routing compiles canonical test groups

```labkit-change
id: LK-20260722-owner-minimal-validation-routing
date: 2026-07-22
sequence: 157
type: test
compatibility: compatible
scope: Test routing
scope: Test ownership
```

## Context

Changed-file validation could widen an App capability change to a family-level
test folder, depend on implicit contract discovery, or execute the same test
through overlapping folder routes. The migration ledger recorded the required
zero-debt replacement: explicit App owners, framework consumer closure, and
one execution of each selected official test.

## Decision and rationale

Treat route selection and execution as separate concerns. Preserve every
semantic owner route with its reason, discover the matching official tests,
then union canonical identities into one non-GUI and one hidden-GUI execution
group. This keeps coverage reviewable without paying for duplicate execution.

## Changes

- Moved App-specific tests into explicit `appContract`, `workbench`, source
  capability, `smoke`, and `isolatedPath` owners; moved cross-App audits to
  project ownership.
- Removed family-root and overlap-based route suppression.
- Added canonical test-union compilation, deterministic feature-tagged smoke
  selection, direct facade-consumer routing, and safe all-smoke fallback when
  required feature metadata is absent.
- Focused ordinary App-manual, history, and library-documentation routes while
  retaining complete contracts for renderer and policy changes.
- Added dynamic guards for every public App's owned contracts and smoke proof,
  valid source-capability scopes, unique canonical execution, and focused
  documentation routes.

## User and data impact

No App behavior, saved project, scientific result, or export changes. Local
`changedFast` feedback is smaller and deterministic; CI remains the complete
headless and hidden-GUI validation gate.

## Compatibility and migration

No saved-data migration is required. The active test-routing migration ledger
is retired; future routing changes must extend the durable ownership rules and
their guardrails rather than restore compatibility fallbacks.

## Validation

- Focused build-routing guardrails, App ownership contracts, and moved
  cross-App contracts.
- One final `buildtool changedFast` run for the completed diff.

## Evidence

The planner prints all semantic routes and the canonical execution count,
including the number of repeated selections removed. The final local gate and
CI provide the executable evidence for the exact merged diff.

## Known limitations and follow-up

Hidden GUI smoke tests validate bounded launch/layout behavior, not native
dialogs, pointer feel, visual quality, or scientific interpretation; those
remain manual review responsibilities.
