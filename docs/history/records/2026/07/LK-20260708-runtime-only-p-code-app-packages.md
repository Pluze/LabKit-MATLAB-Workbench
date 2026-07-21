# Runtime-only P-code app packages

```labkit-change
id: LK-20260708-runtime-only-p-code-app-packages
date: 2026-07-08
sequence: 41
type: refactor
compatibility: compatible
scope: historical project evolution
```

## Context

Single-app P-code packages included a P-coded copy of the full launcher even
though their purpose was to run one protected app. That exposed maintenance and
packaging actions that were meaningful only in a source checkout.

## Decision and rationale

Make P-code output a minimal runtime package with a direct app entry script.
Keep the full launcher in source and source-package distributions, where its
installation, profiling, and packaging tools are available.

## Changes

- Project deployment tooling, no component version change.

- `Package P-code` now creates a runtime-only single-app package instead of
  shipping a P-coded LabKit launcher and launcher maintenance tools.
- P-code package manifests and README instructions point users to the direct
  `run_<app_command>` entry file.
- P-code packaging no longer requires `labkit_launcher.m` or `labkit_launcher.p`
  to exist in the package root being used as the runtime source.

## User and data impact

Recipients of a P-code package start the protected app with
`run_<app_command>` and no longer see unrelated launcher maintenance actions.
The protected app and its data formats are unchanged.

## Compatibility and migration

- Users of P-code packages should run `run_<app_command>` from the unzipped
  package instead of `labkit_launcher`. Source packages still include and
  support the launcher.

## Validation

Commit `75f63f1` expanded `PackageLabKitAppToolTest` for runtime-only package
contents and updated the generated package instructions.

## Evidence

- Mainline commit `75f63f1`.

## Known limitations and follow-up

P-code packages intentionally omit source-oriented launcher features. Users who
need installation or packaging tools should use a source or source-package
distribution.
