# Chrono Overlay adopts one version-aware project migration entry

```labkit-change
id: CHG-20260716-chrono-overlay-project-spec
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_ChronoOverlay_app | 1.4.1 -> 1.4.2
```

## Why

Chrono Overlay split product metadata across three files and represented its only payload upgrade as a separately named `migrateProjectV1ToV2.m` file in a generic lifecycle package. Adding another schema version would have added yet another file and exposed migration sequencing to the App definition.

### Accepted choice

Make `definition.m` the product declaration and `projectSpec.m` the sole durable-schema entry. Its `Migrate(project, fromVersion)` callback owns App semantics for one version step; Runtime V2 owns the loop, version increment, validation after every step, and unsupported-envelope handling.

## What changed

- Consolidated project creation, validation, and migration in one project spec.
- Replaced the per-version migration file with one version-aware local function.
- Moved transient DTA reconstruction to a package-root session factory.
- Removed separate requirements, version, and generic lifecycle files.
- Kept DTA parsing, pulse-gap alignment, interpolation, plots, and exports unchanged.

## Impact

Launch, plotting, save/load, v1 project upgrade, and CSV export behavior remain unchanged. Maintainers now add future schema cases in one ordered migration entry instead of editing both definition wiring and file inventories.

## Compatibility and limits

Version-1 payloads still remove the obsolete decoded `inputs.items` field so portable source records remain the only durable input. Version-2 payloads are unchanged and need no migration.

### Remaining limits

Only v1-to-v2 is currently required. Future cases remain App-owned in the same function; they must not bypass the framework's stepwise validation loop.
