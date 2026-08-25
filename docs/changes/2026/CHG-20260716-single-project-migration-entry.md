# One project migration entry per App

```labkit-change
id: CHG-20260716-single-project-migration-entry
date: 2026-07-16
type: feat
compatibility: compatible
component: labkit.ui | 7.2.1 -> 7.3.0
```

## Why

Runtime V2 already applied project migrations sequentially, but each App had to expose a cell array containing every historical version-step function. Schema growth therefore increased files and wiring even though the framework owned the actual migration loop.

### Accepted choice

Give each persistent App one migration entry. `Migrate(project,fromVersion)` upgrades exactly one step; Runtime V2 supplies each missing version in order, validates every intermediate payload, and continues to the current version.

## What changed

- Added the scalar `Project.Migrate` callback.
- Kept per-step serialization validation, newer-version rejection, atomic load behavior, final project validation, session rebuild, and dirty upgrade state unchanged.
- Converted the framework's version-1-to-3 round-trip fixture to one callback with two version cases.
- Retained `Project.Migrations` only as a temporary bridge for existing Apps.

## Impact

Saved projects behave as before. App maintainers can keep create, validate, and every schema transition as local functions in one `projectSpec.m` instead of maintaining a growing migration-file registry.

## Compatibility and limits

The contract is additive within UI 7. Existing Apps continue to load during family-sized migration. An App must not declare both migration forms.

### Remaining limits

Existing Apps still need their lifecycle functions consolidated into `projectSpec.m`. The legacy migration-array bridge will be removed after the last family is migrated.
