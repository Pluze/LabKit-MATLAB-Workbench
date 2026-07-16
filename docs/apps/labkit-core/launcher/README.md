# LabKit Launcher

The LabKit Launcher is the installed workbench entry point. It discovers apps,
prepares their MATLAB paths, checks requirements, starts normal or debug
sessions, manages installed versions, opens app documentation, and exposes
source-checkout maintenance tools. It is intentionally self-contained so a
single surviving `labkit_launcher.m` can repair an incomplete ZIP installation.

## Start The Launcher

```matlab
labkit_launcher
```

The window paints before app discovery completes. Its status area first reports
that the app list is loading, then shows the selected app, integrity problems,
tool availability, or the active maintenance operation.

## Launcher Window

| Group | Action | Behavior |
| --- | --- | --- |
| Run Apps | **Open Selected App** | Checks the selected app requirements, adds the app root, and launches normally. |
| Run Apps | **Open Debug** | Launches the same app with diagnostic tracing enabled. |
| Run Apps | **Refresh App List** | Repeats public and configured private-app discovery without restarting the launcher. |
| Run Apps | **Documentation and History** | Opens the generated manual for the selected app. |
| Versions and Install | **Latest** | Installs the current `main` branch archive. |
| Versions and Install | **Release** | Installs the latest stable GitHub release. |
| Versions and Install | **Versions** | Opens the release, tag, and commit selector for deliberate upgrade or rollback. |
| Development and Maintenance | **Update Documentation** | Regenerates `site/` with the repository-owned documentation compiler. |
| Development and Maintenance | **Run Code Analyzer** | Scans the checkout and writes JSON and HTML Code Analyzer reports. |
| Development and Maintenance | **Profile Selected App** | Starts the selected app under the MATLAB profiler and saves its report when the app closes. |
| Development and Maintenance | **Clean Artifacts** | Removes ignored generated reports under `artifacts/`; it does not delete app projects or exported laboratory results. |
| Package and Publish | **Package Checked** | Creates one source ZIP containing all checked apps and their runtime support. |
| Package and Publish | **Checked P-code** | Creates a runtime-only ZIP with MATLAB source encoded as P-code. |

Double-clicking an app row is equivalent to selecting it and opening it
normally. The checkbox column controls package membership; ordinary launch
selection does not change the checked set.

## Programmatic Calls

The launcher exposes a small non-GUI surface:

```matlab
fig = labkit_launcher;
apps = labkit_launcher("list");
info = labkit_launcher("version");
page = labkit_launcher("documentation", "labkit_CIC_app");
```

| Call | Result |
| --- | --- |
| `labkit_launcher` | Opens the window; optionally returns its figure handle. |
| `labkit_launcher("list")` | Returns the discovered app catalog as a table without opening the launcher window. |
| `labkit_launcher("version")` | Returns launcher name, display name, semantic version, and update date. |
| `labkit_launcher("documentation", appCommand)` | Returns the local generated HTML page for one discovered app command. |

Unsupported modes, empty documentation commands, extra inputs, and more than
one requested GUI output raise `labkit_launcher:InvalidInput` or
`labkit_launcher:TooManyOutputs` errors.

## App Discovery

Public apps are discovered from `apps/**/labkit_*_app.m`. Each entry point
supplies display metadata, family, command, version, requirements, and launch
routing. Local private apps may be discovered from `private_apps/apps/` or
paths named by `LABKIT_PRIVATE_APP_ROOTS`; their repositories and manuals
remain private.

The launcher adds only the paths needed for the selected app. It does not use
`genpath` to expose every app helper globally. Refresh the app list after adding,
removing, or updating an app while the launcher remains open.

## Installation And Recovery

The downloaded launcher can begin in an otherwise empty folder. **Latest**,
**Release**, and **Versions** download a repository archive, validate its
contents, preserve a dated `LabKit-previous-*` recovery copy, and then replace
the managed runtime. Keep experimental data and exports outside that runtime
folder because installed code is replaceable.

Installed apps run offline unless their own inputs use a network location.
Version discovery and update actions require network access. Source and P-code
deployment packages have different contents; see
[App Deployment Packages](../../../development/tools/deployment.md).

## Maintenance Tools

Maintenance buttons are enabled only when their corresponding source-checkout
tool is available. The same operations can be called directly from MATLAB:

- [Code Analyzer Reports](../../../development/tools/codecheck.md)
- [App Deployment Packages](../../../development/tools/deployment.md)
- [Documentation Build Tools](../../../development/tools/documentation.md)
- [Performance Profiling](../../../development/tools/profiling.md)

These tools produce ignored artifacts. They are not app runtime APIs and do
not alter scientific data.

## Development History

The launcher began as the visible entry point for UI 2.0, then gained
self-contained repair updates, version selection, private-app discovery,
profiling and packaging actions, early startup feedback, and direct app
documentation links. The generated **Change history** below lists every record
whose metadata names `labkit_launcher` in linear sequence.

Key milestones:

- [v2.0 launcher and UI 2.0](../../../history/records/2026/06/LK-20260615-v2-launcher-and-ui2.md)
- [Self-contained launch and image workflow refinement](../../../history/records/2026/06/LK-20260621-v2-2-v2-3-image-workflows.md)
- [Launcher manager and stale callback repair](../../../history/records/2026/06/LK-20260626-launcher-manager-and-stale-callback-fix.md)
- [Profiling and validation speedups](../../../history/records/2026/07/LK-20260702-profiling-and-validation-speedups.md)
- [Searchable documentation and launcher workflow groups](../../../history/records/2026/07/LK-20260715-documentation-site.md)

## Related Documentation

- [Getting Started](../../../getting-started/README.md)
- [LabKit Apps](../../README.md)
- [LabKit Core Apps](../README.md)
- [Architecture](../../../development/architecture.md)
- [Private Apps](../../../development/private-apps.md)
- [Release Process](../../../development/release.md)
