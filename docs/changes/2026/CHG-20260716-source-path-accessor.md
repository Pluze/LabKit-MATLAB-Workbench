# Runtime owns portable source-reference details

```labkit-change
id: CHG-20260716-source-path-accessor
date: 2026-07-16
type: feat
compatibility: compatible
component: labkit.ui | 7.3.0 -> 7.4.0
```

## Why

Runtime V2 owned source creation, rebasing, relinking, and validation, but an App still had to read `reference.originalPath` whenever it loaded or displayed a source. This exposed the nested persistence representation throughout session factories, actions, presenters, and workflow packages. Several Apps then added their own identical path loops or ID lookup functions.

### Accepted choice

Keep source `id`, `role`, and `required` as stable App-facing project data, but treat the nested portable reference as a runtime-owned value. Add one pure `labkit.ui.runtime.sourcePaths` accessor that works before UI construction and therefore serves session creation as well as actions and presentation.

Passing UI-bound injected services into `CreateSession` was rejected: it would couple otherwise pure state reconstruction to figure, queue, dialog, and resource-service construction merely to read a path.

## What changed

- Added `sourcePaths(sources)` for paths in source order.
- Added `sourcePaths(sources,ids)` for strict lookup in requested ID order.
- Defined empty, malformed-reference, and unknown-ID behavior in executable public help and unit tests.
- Stopped documenting portable-reference fields as an App read contract.
- Added the accessor to the guarded public UI runtime surface.

## Impact

Saved projects and file resolution behave unchanged. App code can now read, compare, load, and present source paths without knowing how a portable reference stores its current or relative location.

## Compatibility and limits

The addition is compatible within UI 7. Existing direct field reads continue to work temporarily, but tracked Apps will move to the accessor during their family-by-family Runtime V2 consolidation. No project migration is required.

### Remaining limits

Existing App-local path loops remain until their owning App commits are migrated and behavior-tested. Once all consumers use this accessor, a contract guard will prevent production Apps from reading portable-reference fields.
