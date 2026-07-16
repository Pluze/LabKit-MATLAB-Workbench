# One project migration entry per App

```labkit-change
schema: 2
id: LK-20260716-single-project-migration-entry
date: 2026-07-16
sequence: 81
type: feat
compatibility: additive
component: `labkit.ui` | `7.2.1 -> 7.3.0`
scope: Runtime V2 projects
scope: App authoring
```

## Context

Runtime V2 already applied project migrations sequentially, but each App had
to expose a cell array containing every historical version-step function.
Schema growth therefore increased files and wiring even though the framework
owned the actual migration loop.

## Decision and rationale

Give each persistent App one migration entry. `Migrate(project,fromVersion)`
upgrades exactly one step; Runtime V2 supplies each missing version in order,
validates every intermediate payload, and continues to the current version.

## Changes

- Added the scalar `Project.Migrate` callback.
- Kept per-step serialization validation, newer-version rejection, atomic
  load behavior, final project validation, session rebuild, and dirty upgrade
  state unchanged.
- Converted the framework's version-1-to-3 round-trip fixture to one callback
  with two version cases.
- Retained `Project.Migrations` only as a temporary bridge for existing Apps.

## User and developer impact

Saved projects behave as before. App maintainers can keep create, validate,
and every schema transition as local functions in one `projectSpec.m` instead
of maintaining a growing migration-file registry.

## Compatibility and migration

The contract is additive within UI 7. Existing Apps continue to load during
family-sized migration. An App must not declare both migration forms.

## Validation

The Runtime V2 project test opens a version-1 payload in a version-3 App,
executes both steps through one callback, verifies final data and source
relinking, saves the current payload version, and checks failure atomicity.

## Evidence

- [Runtime and Lifecycle](../../../../framework/runtime.md) documents the
  project declaration and loop.
- [App Development](../../../../development/app-development.md) describes the
  single project file.

## Known limitations and follow-up

Existing Apps still need their lifecycle functions consolidated into
`projectSpec.m`. The legacy migration-array bridge will be removed after the
last family is migrated.
