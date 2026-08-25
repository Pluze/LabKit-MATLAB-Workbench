# v1.0: app-owned packages and a standard test platform

```labkit-change
id: CHG-20260606-v1-foundation
date: 2026-06-06
type: refactor
compatibility: compatible
component: repository
```

## Why

The pre-release work had produced many useful apps and library functions, but the repository still carried large entry points, custom test routing, UI compatibility aliases, and helper ownership that was difficult to explain. Releasing that state as a stable foundation required more than assigning a version number.

### Accepted choice

Make each app package responsible for its runner, callbacks, presenters, and private workflow helpers. Use MATLAB's official test platform as the common runner, retain focused GUI gesture tests where automation was meaningful, and remove compatibility abstractions that no longer represented supported code.

## What changed

- Added the official MATLAB test-platform skeleton and migrated project guardrails and app suites to it.
- Decomposed image, DIC, electrochem, and ECG entry points into app-owned packages and private workflow helpers.
- Added GUI gesture coverage and CI test artifacts.
- Centralized the build-task catalog and separated scheduled coverage from faster routine checks.
- Added Batch Image Crop with a base-MATLAB rotation path.
- Completed DIC package migration and removed toolbox-only unit dependencies from its tested paths.
- Removed obsolete UI compatibility aliases and specialized dual-plot shell APIs in favor of structured form specifications and app-owned plot controls.

## Impact

The v1.0 foundation provided a coherent set of named apps backed by repeatable tests. Batch Image Crop joined the image family, while existing electrochem, DIC, curvature, focus, and ECG workflows retained their app entry points.

The release concentrated on ownership and validation. It did not introduce a single shared project-file format or combine the apps into one monolithic GUI.

## Compatibility and limits

Repository code using removed UI aliases or dispatch routers needed to call the supported app and UI contracts. User-facing app entry points remained the intended launch mechanism.

### Remaining limits

v1.0 still required users to know individual app commands and used the first generation of the UI runtime. The next major release added a launcher and migrated apps to UI 2.0.
