# Test catalog cutover replaces the legacy test tree

```labkit-change
id: CHG-20260723-test-catalog-cutover
date: 2026-07-23
type: test
compatibility: breaking
component: repository
```

## Why

The former test tree mixed stage folders, route wrappers, shared helpers, and executor policy. Authors had to infer where a specification belonged and which selector would exercise it. On Windows, an additional case-sensitive path comparison could reject valid catalog specifications before any behavior ran.

### Accepted choice

Make production ownership, behavioral contract, and execution environment the only selection model. Keep framework mechanics private in `labkittest`; keep only genuinely cross-owner synthetic data in a named fixture package. A test path comparison must be case-insensitive because Windows resolves an existing path with filesystem casing that need not match the configured root spelling.

## What changed

- Replaced the old runner and `tests/cases` tree with exact catalog specifications under `tests/specs`.
- Added semantic authoring and execution entry points: `explain`, `createSpec`, and `run`.
- Removed unreferenced legacy GUI, App-contract, repository, and assertion helpers from the former `tests/shared` bucket.
- Moved the remaining cross-owner synthetic DTA, thermal, RHS, chrono, and gait inputs into `tests/+testfixtures` and qualified every consumer.
- Normalized catalog filesystem paths before ownership comparison and added a Windows regression for differently cased specification-root input.
- Updated the current testing manual, scoped test rules, migration ledger, and generated documentation site.

## Impact

No App behavior, saved project, scientific calculation, export schema, or laboratory data changes. Test authors gain a path-free insertion workflow and machine-readable run artifacts. All fixtures remain synthetic.

## Compatibility and limits

This intentionally removes the unsupported legacy test folders, runner, and selector model. Contributors must use `tests/specs`, `labkittest` semantic selectors, and `tests/+testfixtures` where a synthetic input is genuinely cross-owner. No data migration is required.

### Remaining limits

Hidden-GUI checks remain structural and do not replace manual validation of native dialogs, visual quality, pointer behavior, real-data suitability, or scientific interpretation. The PR must receive green cross-platform CI before merge.
