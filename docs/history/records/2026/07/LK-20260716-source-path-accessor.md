# Runtime owns portable source-reference details

```labkit-change
schema: 2
id: LK-20260716-source-path-accessor
date: 2026-07-16
sequence: 91
type: feat
compatibility: compatible
component: `labkit.ui` | `7.3.0 -> 7.4.0`
scope: Runtime source boundary
scope: App maintenance cost
```

## Context

Runtime V2 owned source creation, rebasing, relinking, and validation, but an
App still had to read `reference.originalPath` whenever it loaded or displayed
a source. This exposed the nested persistence representation throughout
session factories, actions, presenters, and workflow packages. Several Apps
then added their own identical path loops or ID lookup functions.

## Decision and rationale

Keep source `id`, `role`, and `required` as stable App-facing project data, but
treat the nested portable reference as a runtime-owned value. Add one pure
`labkit.ui.runtime.sourcePaths` accessor that works before UI construction and
therefore serves session creation as well as actions and presentation.

Passing UI-bound injected services into `CreateSession` was rejected: it would
couple otherwise pure state reconstruction to figure, queue, dialog, and
resource-service construction merely to read a path.

## Changes

- Added `sourcePaths(sources)` for paths in source order.
- Added `sourcePaths(sources,ids)` for strict lookup in requested ID order.
- Defined empty, malformed-reference, and unknown-ID behavior in executable
  public help and unit tests.
- Stopped documenting portable-reference fields as an App read contract.
- Added the accessor to the guarded public UI runtime surface.

## User and developer impact

Saved projects and file resolution behave unchanged. App code can now read,
compare, load, and present source paths without knowing how a portable
reference stores its current or relative location.

## Compatibility and migration

The addition is compatible within UI 7. Existing direct field reads continue
to work temporarily, but tracked Apps will move to the accessor during their
family-by-family Runtime V2 consolidation. No project migration is required.

## Validation

Unit tests cover source order, requested ID order, empty results, missing IDs,
and invalid runtime references. Package-surface and documentation guardrails
cover the new public contract.

## Evidence

- [Runtime and Lifecycle](../../../../framework/runtime.md)
- [Complete App Tutorial](../../../../development/complete-app.md)

## Known limitations and follow-up

Existing App-local path loops remain until their owning App commits are
migrated and behavior-tested. Once all consumers use this accessor, a contract
guard will prevent production Apps from reading portable-reference fields.
