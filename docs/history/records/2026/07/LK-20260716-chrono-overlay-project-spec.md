# Chrono Overlay adopts one version-aware project migration entry

```labkit-change
id: LK-20260716-chrono-overlay-project-spec
date: 2026-07-16
sequence: 86
type: refactor
compatibility: compatible
component: `labkit_ChronoOverlay_app` | `1.4.1 -> 1.4.2`
scope: Electrochemistry
scope: Project lifecycle
```

## Context

Chrono Overlay split product metadata across three files and represented its
only payload upgrade as a separately named `migrateProjectV1ToV2.m` file in a
generic lifecycle package. Adding another schema version would have added yet
another file and exposed migration sequencing to the App definition.

## Decision and rationale

Make `definition.m` the product declaration and `projectSpec.m` the sole
durable-schema entry. Its `Migrate(project, fromVersion)` callback owns App
semantics for one version step; Runtime V2 owns the loop, version increment,
validation after every step, and unsupported-envelope handling.

## Changes

- Consolidated project creation, validation, and migration in one project spec.
- Replaced the per-version migration file with one version-aware local function.
- Moved transient DTA reconstruction to a package-root session factory.
- Removed separate requirements, version, and generic lifecycle files.
- Kept DTA parsing, pulse-gap alignment, interpolation, plots, and exports
  unchanged.

## User and data impact

Launch, plotting, save/load, v1 project upgrade, and CSV export behavior remain
unchanged. Maintainers now add future schema cases in one ordered migration
entry instead of editing both definition wiring and file inventories.

## Compatibility and migration

Version-1 payloads still remove the obsolete decoded `inputs.items` field so
portable source records remain the only durable input. Version-2 payloads are
unchanged and need no migration.

## Validation

Unit tests call the new migration entry with a synthetic v1 payload and verify
validation, session reconstruction, pulse alignment, interpolation, and
presenter output. The hidden GUI workflow covers real launch, source loading,
plotting, and export through the consolidated definition.

## Evidence

- [Chrono Overlay](../../../../apps/electrochemistry/chrono-overlay/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

Only v1-to-v2 is currently required. Future cases remain App-owned in the same
function; they must not bypass the framework's stepwise validation loop.
