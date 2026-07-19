# Launcher reads the single App definition

```labkit-change
schema: 2
id: LK-20260716-launcher-definition-metadata
date: 2026-07-16
sequence: 78
type: refactor
compatibility: compatible
component: `labkit_launcher` | `1.5.0 -> 1.5.1`
scope: App discovery
scope: Product metadata ownership
```

## Context

The launcher discovered entrypoints independently from App runtime creation,
but obtained versions by parsing a separate package `version.m`. That kept the
old metadata file alive even after Runtime V2 gained a single definition
contract.

## Decision and rationale

Keep discovery lightweight and self-contained while changing its source of
truth. The launcher now reads `AppVersion` and `Updated` literals from the
App's `definition.m`; it does not execute the definition or start the App.

## Changes

- Preferred `definition.m` product metadata during public and private App
  discovery.
- Added a synthetic private-App catalog test with no `version.m` file.
- Retained a documented internal fallback only for Apps awaiting migration.

## User and developer impact

Launcher catalogs continue to show version and update dates. A migrated App
does not need a second metadata file solely for discovery.

## Compatibility and migration

The change is compatible. Existing Apps remain discoverable through the
temporary fallback; migrated Apps use only their definition. The fallback is
removed after the last App migration.

## Validation

The launcher catalog test creates an isolated App definition, points private
discovery at it, and verifies the returned version and date without a
`version.m` file.

## Evidence

- [LabKit Launcher](../../../../apps/labkit-core/launcher/README.md) explains
  definition-backed discovery.
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md) defines the App
  product metadata fields.

## Known limitations and follow-up

P-code packaging metadata will be audited with the deployment workflow before
the transitional parser fallback is removed.
