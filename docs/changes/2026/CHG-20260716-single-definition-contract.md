# Single-definition App product contract

```labkit-change
id: CHG-20260716-single-definition-contract
date: 2026-07-16
type: feat
compatibility: compatible
component: labkit.ui | 7.1.0 -> 7.2.0
```

## Why

Every App repeated product metadata and facade requirements in `version.m` and `requirements.m`, while `definition.m` separately described the product's runtime behavior. Thin entrypoints had to join all three factories, and the launcher and release guardrails treated the duplicate files as separate facts.

### Accepted choice

Make `definition.m` the one App product contract. Product identity, version, requirements, layout, and optional runtime capabilities now have one owner. The public entrypoint can delegate through `launch(@definition, varargin{:})`.

## What changed

- Added `Command`, optional `DisplayName`, `Family`, `AppVersion`, `Updated`, and `Requirements` fields to `labkit.ui.runtime.define`.
- Added single-definition launch and lightweight `version` and `requirements` request handling.
- Kept the previous three-factory launch form only as a temporary bridge while existing Apps move in reviewed family-sized changes.
- Extended the minimal real-GUI launch test to obtain all metadata from the same definition.

## Impact

App users see no workflow or scientific change. App authors no longer need to keep three product declarations synchronized after their App is migrated.

## Compatibility and limits

The addition is compatible within UI 7. Existing definitions continue to run during the migration window. Each App will move its exact metadata and facade ranges into `definition.m` before its redundant files are removed. The bridge is not a permanent supported architecture.

### Remaining limits

Existing Apps, launcher static discovery, release version guards, tutorials, and the App-builder skill still need family-by-family migration. The legacy launch bridge is removed only after those consumers no longer use it.
