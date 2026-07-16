# Figure Studio adopts one product definition

```labkit-change
schema: 2
id: LK-20260716-figure-studio-single-definition
date: 2026-07-16
sequence: 79
type: refactor
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.2.1 -> 0.2.2`
component: `labkit.ui` | `7.2.0 -> 7.2.1`
scope: LabKit Core
scope: App structure
```

## Context

Figure Studio declared its command, names, family, App version, and LabKit
requirement in two files separate from the runtime definition. Its entrypoint
joined all three factories even though they described one product.

## Decision and rationale

Use Figure Studio as the first reviewed App migration to the single-definition
contract. This validates the reduced structure on an App that also accepts a
typed axes handoff, without changing its plotting or export behavior.

## Changes

- Moved exact product metadata and the UI requirement into `definition.m`.
- Reduced the public entrypoint to one definition plus its existing typed
  request adapter.
- Removed the redundant `requirements.m` and `version.m` files.
- Taught the version guard to use `AppVersion` in a migrated definition while
  comparing the first migration against the previous `version.m` baseline.
- Fixed the shared source reconciler so it creates the canonical empty source
  array without first constructing an invalid empty-ID placeholder record.
- Added `services.results.emptyOutputs()` and used it for Figure Studio's
  variable-length export manifest instead of constructing an invalid empty-ID
  placeholder output.

## User and developer impact

Launch, axes handoff, style controls, project payload, FIG reading, plot
snapshot extraction, and all export formats retain their existing behavior.
Maintainers now update one product contract instead of three files.

## Compatibility and migration

The App command and project ID are unchanged. App version metadata requests
still return the same fields through the public entrypoint. Existing project
payloads remain at version 1 and require no data migration.

## Validation

Focused tests cover ordinary launch, axes handoff, style changes, project
round-trip, exports, launcher discovery, requirements/version requests, and
version/history governance.

## Evidence

- [Figure Studio](../../../../apps/labkit-core/figure-studio/README.md)
  documents the unchanged workflow and new definition ownership.
- [Runtime and Lifecycle](../../../../framework/runtime.md) defines the shared
  product contract.

## Known limitations and follow-up

Figure Studio still has a meaningful version-1 project schema, rebuildable
plot session cache, and startup resource installation. These will move to the
projectSpec/action capability model after the framework supports that model;
they were not deleted merely to reduce file count.
