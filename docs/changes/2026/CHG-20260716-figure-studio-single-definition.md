# Figure Studio adopts one product definition

```labkit-change
id: CHG-20260716-figure-studio-single-definition
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_FigureStudio_app | 0.2.1 -> 0.2.2
component: labkit.ui | 7.2.0 -> 7.2.1
```

## Why

Figure Studio declared its command, names, family, App version, and LabKit requirement in two files separate from the runtime definition. Its entrypoint joined all three factories even though they described one product.

### Accepted choice

Use Figure Studio as the first reviewed App migration to the single-definition contract. This validates the reduced structure on an App that also accepts a typed axes handoff, without changing its plotting or export behavior.

## What changed

- Moved exact product metadata and the UI requirement into `definition.m`.
- Reduced the public entrypoint to one definition plus its existing typed request adapter.
- Removed the redundant `requirements.m` and `version.m` files.
- Taught the version guard to use `AppVersion` in a migrated definition while comparing the first migration against the previous `version.m` baseline.
- Fixed the shared source reconciler so it creates the canonical empty source array without first constructing an invalid empty-ID placeholder record.
- Added `services.results.emptyOutputs()` and used it for Figure Studio's variable-length export manifest instead of constructing an invalid empty-ID placeholder output.

## Impact

Launch, axes handoff, style controls, project payload, FIG reading, plot snapshot extraction, and all export formats retain their existing behavior. Maintainers now update one product contract instead of three files.

## Compatibility and limits

The App command and project ID are unchanged. App version metadata requests still return the same fields through the public entrypoint. Existing project payloads remain at version 1 and require no data migration.

### Remaining limits

Figure Studio still has a meaningful version-1 project schema, rebuildable plot session cache, and startup resource installation. These will move to the projectSpec/action capability model after the framework supports that model; they were not deleted merely to reduce file count.
