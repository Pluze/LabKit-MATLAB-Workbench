# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; completed work belongs in component history.

## Active debt

Last audited: 2026-07-25.

```text
toolbox-product-debt: none
architecture-migration-debt: none
compatibility-retirement-debt: none
```

There are no active entries. The completed test-framework parity audit was
removed after every App row was covered or explicitly retired, mapped
automation selected the retained evidence, and the bounded ManualChecks model
was established. Saved-project migrations and declared read-only importers are
supported persistence behavior, not an open roadmap. The former DTA parallel
field aliases were retired in `labkit.dta` 3.0.

## Maintaining the ledger

Open an entry only for a concrete current problem with an owner, observable
effect, focused test, completion criteria, and removal condition. Do not copy a
completed audit, supported behavior inventory, speculative cleanup, file-size
concern, or possible future abstraction into this file.

Temporary MathWorks Toolbox use must record the exact source symbol, product,
owner, repository fallback, fallback test, idempotency evidence, numeric parity
outputs and tolerance, and the condition for deleting the Toolbox branch. Its
machine-readable declaration lives in `tests/+labkittest/toolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history.
