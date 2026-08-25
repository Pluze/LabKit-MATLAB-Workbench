# Launcher reads the single App definition

```labkit-change
id: CHG-20260716-launcher-definition-metadata
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_launcher | 1.5.0 -> 1.5.1
```

## Why

The launcher discovered entrypoints independently from App runtime creation, but obtained versions by parsing a separate package `version.m`. That kept the old metadata file alive even after Runtime V2 gained a single definition contract.

### Accepted choice

Keep discovery lightweight and self-contained while changing its source of truth. The launcher now reads `AppVersion` and `Updated` literals from the App's `definition.m`; it does not execute the definition or start the App.

## What changed

- Preferred `definition.m` product metadata during public and private App discovery.
- Added a synthetic private-App catalog test with no `version.m` file.
- Retained a documented internal fallback only for Apps awaiting migration.

## Impact

Launcher catalogs continue to show version and update dates. A migrated App does not need a second metadata file solely for discovery.

## Compatibility and limits

The change is compatible. Existing Apps remain discoverable through the temporary fallback; migrated Apps use only their definition. The fallback is removed after the last App migration.

### Remaining limits

P-code packaging metadata will be audited with the deployment workflow before the transitional parser fallback is removed.
