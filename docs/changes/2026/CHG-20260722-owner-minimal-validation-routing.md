# Owner-minimal validation routing compiles canonical test groups

```labkit-change
id: CHG-20260722-owner-minimal-validation-routing
date: 2026-07-22
type: test
compatibility: compatible
component: repository
```

## Why

Changed-file validation could widen an App capability change to a family-level test folder, depend on implicit contract discovery, or execute the same test through overlapping folder routes. The migration ledger recorded the required zero-debt replacement: explicit App owners, framework consumer closure, and one execution of each selected official test.

### Accepted choice

Treat route selection and execution as separate concerns. Preserve every semantic owner route with its reason, discover the matching official tests, then union canonical identities into one non-GUI and one hidden-GUI execution group. This keeps coverage reviewable without paying for duplicate execution.

## What changed

- Moved App-specific tests into explicit `appContract`, `workbench`, source capability, `smoke`, and `isolatedPath` owners; moved cross-App audits to project ownership.
- Removed family-root and overlap-based route suppression.
- Added canonical test-union compilation, deterministic feature-tagged smoke selection, direct facade-consumer routing, and safe all-smoke fallback when required feature metadata is absent.
- Preserved physical suite-folder case during selector discovery and made an isolated App sample derive the repository root from the shared test setup, so owner paths behave consistently on Linux, macOS, and Windows.
- Focused ordinary App-manual, history, and library-documentation routes while retaining complete contracts for renderer and policy changes.
- Added dynamic guards for every public App's owned contracts and smoke proof, valid source-capability scopes, unique canonical execution, and focused documentation routes. Test classes also reject migrated test-shaped methods stranded in non-discoverable static-private blocks.

## Impact

No App behavior, saved project, scientific result, or export changes. Local `changedFast` feedback is smaller and deterministic; CI remains the complete headless and hidden-GUI validation gate.

## Compatibility and limits

No saved-data migration is required. The active test-routing migration ledger is retired; future routing changes must extend the durable ownership rules and their guardrails rather than restore compatibility fallbacks.

### Remaining limits

Hidden GUI smoke tests validate bounded launch/layout behavior, not native dialogs, pointer feel, visual quality, or scientific interpretation; those remain manual review responsibilities.
