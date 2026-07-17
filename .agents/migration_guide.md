# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; exact validation commands belong in
`docs/development/testing.md`; completed work belongs in component history.

## Active debt

Last audited: 2026-07-17.

```text
toolbox-product-debt: none
```

## Intentional compatibility

Read-only saved-data compatibility is not automatically migration debt. Retain
it when current user files need it and the current writer always emits the
current format:

- Video Marker imports its declared legacy project variable and writes the
  current `labkitProject` envelope.
- Current App project specs migrate supported older payload versions through
  one version-aware `Migrate` entry.
- `labkit.dta` retains documented legacy field aliases beside canonical,
  unit-explicit fields until a future major-version decision.

Do not use a saved-data promise to justify old source layouts, launch factories,
migration callback collections, or undocumented UI nodes.

## Maintaining the ledger

Open an entry only for a concrete current problem with an owner, observable
effect, focused test, completion criteria, and removal condition. Do not treat
file length, helper count, or a possible future abstraction as migration debt.

Temporary MathWorks Toolbox use must record the exact source symbol, product,
owner, repository fallback, fallback test, idempotency evidence, numeric parity
outputs and tolerance, and the condition for deleting the Toolbox branch. Its
machine-readable declaration lives in
`tests/runner/labkitToolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history when project policy requires them.
