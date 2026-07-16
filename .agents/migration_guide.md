# Migration Debt Ledger

This file records only active migration debt. Current architecture belongs in
`docs/`; validation commands belong in `docs/development/testing.md`; completed
work belongs in component history.

## Current debt

Last audited: 2026-07-16.

```text
ui-runtime-v2: none
app-structure-debt: none
app-project-and-result-contract-debt: none
toolbox-product-debt: none
```

All twenty public apps use `labkit.ui.runtime.launch/define`, canonical
project/session state, data-only layouts, presenters, semantic actions, and
managed interactions/resources. There are no package-root lifecycle runners,
app-family `private/` workflow implementations, or Runtime V1 writers.

Read-only compatibility is not migration debt. Current intentional bridges are:

- Video Marker imports its named legacy project variable and always writes the
  current `labkitProject` envelope.
- Chrono Overlay and Batch Crop retain ordered V1-to-V2 project migrations.
- `labkit.dta` retains documented legacy field aliases beside canonical,
  unit-explicit fields until a future major-version change.

## Opening debt

Add an entry only for a concrete, current problem with ownership, behavior,
testability, or cognitive load. Record its owner, affected paths, observable
completion condition, focused validation, and removal condition. Do not open
debt for file length, helper count, a completed historical route, or a desired
refactor without a demonstrated defect.

Temporary MathWorks Toolbox use must also record the exact source and symbol,
product, repository-owned fallback, fallback test, idempotency evidence,
numeric parity outputs and tolerance, and the condition for deleting the
Toolbox branch. The matching declaration lives in
`tests/runner/labkitToolboxDebt.m`.

When an entry is resolved, delete it and any debt-specific guardrail in the
same change. Keep this ledger compact when every field is `none`.
