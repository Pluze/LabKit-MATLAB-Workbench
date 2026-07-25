# Migration ledger returns to zero active debt

```labkit-change
id: LK-20260725-migration-ledger-closure
date: 2026-07-25
sequence: 165
type: docs
compatibility: compatible
component: `labkit.app`
scope: Migration debt ledger
scope: Saved-project compatibility
scope: Test framework parity
```

## Context

The migration ledger still contained a completed test-framework parity audit,
its execution plan, and an unbounded “Intentional compatibility” inventory.
That mixed historical evidence, current supported persistence, and real
retirement debt in one active roadmap.

## Decision and rationale

The ledger now reports only unresolved migration or compatibility-retirement
work. Completed parity evidence is historical. Ordered project migrations and
exact read-only MAT importers are formal saved-data contracts because current
writers emit only the current envelope; duplicate DTA live fields were retired
rather than classified as indefinite compatibility.

## Changes

- Removed the completed App-by-App parity report and execution plan.
- Replaced the compatibility inventory with zero active debt.
- Documented the current-writer, ordered-migration, exact-import, and
  future-version rejection boundaries in the Runtime manual.
- Added runtime evidence for migrations, legacy imports, and newer payload
  rejection.
- Confirmed every one of the 21 App project specs maps to owner persistence
  evidence.

## User and data impact

Supported older project files continue to load through their declared App
callbacks. Current saves remain current-format only. No source or saved project
is rewritten by this documentation and test-governance change.

## Compatibility and migration

No supported project reader was removed. The DTA alias retirement and EIS
project migration are recorded in their separate component changes.

## Validation

The framework App SDK source contract passed, including clean Debug startup,
ordered project migration, exact legacy import, and rejection of a newer
payload. A repository-wide planner audit found selectable persistence evidence
for all 21 project specs.

## Evidence

- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)
- [App Development](../../../../development/build-apps/app-development.md)
- [Testing](../../../../development/maintain-and-release/testing.md)

## Known limitations and follow-up

The zero-debt ledger is not a claim that no future migration will be needed.
A new concrete debt entry must name its owner, observable effect, evidence,
completion criteria, and removal condition.
