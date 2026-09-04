# LabKit Launcher

```labkit-page
id: app-launcher
type: landing
audience: app-user
summary: Find and open LabKit apps, check requirements, manage installed versions, read documentation, and access source-checkout maintenance tools.
```

The LabKit Launcher is the main place to find and open Apps, check their requirements, manage installed versions, open documentation, and use source-checkout maintenance tools. A downloaded `labkit_launcher.m` can also install LabKit or repair an incomplete installation.

## Start The Launcher

```matlab
labkit_launcher
```

The window paints before app discovery completes. Its status area first reports that the app list is loading, then shows the selected app, integrity problems, tool availability, or the active maintenance operation.

## Launcher Window

| Group | Action | Behavior |
| --- | --- | --- |
| Run Apps | **Open Selected App** | Checks the selected App's requirements and opens it. |
| Run Apps | **Refresh App List** | Repeats public and configured private-app discovery without restarting the launcher. |
| Run Apps | **Open App Guide** | Opens the current online guide for the selected App. |
| Run Apps | **View Launch Log** | Opens the current Launcher's timed discovery and App-startup events. |
| Versions and Install | **Latest** | Installs the latest published stable GitHub Release. |
| Versions and Install | **Versions** | Lists published stable GitHub Releases with their publication date and release information for deliberate upgrade or rollback. |
| Development and Maintenance | **Doc Generation** | Rebuilds the complete ignored `site/` folder from the current Markdown and public MATLAB help. It does not open a page or choose between online and local help. |
| Development and Maintenance | **Run Code Analyzer** | Scans the checkout and writes JSON and HTML Code Analyzer reports. |
| Development and Maintenance | **Profile Selected App** | Starts the selected app under the MATLAB profiler and saves its report when the app closes. |
| Development and Maintenance | **Clean Artifacts** | Removes ignored generated reports under `artifacts/`; it does not delete app projects or exported laboratory results. |
| Package and Publish | **Package Checked** | Creates one source ZIP containing all checked apps and their runtime support. |

Double-clicking an app row is equivalent to selecting it and opening it normally. The checkbox column controls package membership; ordinary launch selection does not change the checked set. Click any column heading to sort it and click again to reverse the order. Selection and double-click actions continue to address the underlying App after sorting. The application table places **Family** immediately before **App** so related tools remain visually grouped while their individual names stay easy to scan.

When startup begins, the launcher disables its App table and actions, changes the open button to **Starting App...**, and reports whether it is preparing the App or invoking its window. Duplicate clicks are ignored until invocation finishes. Success restores the controls and reports elapsed launch time without forcing an additional synchronous full-window paint; MATLAB can finish painting the new App after the Launcher callback returns. Failure reports the identifier and message and offers repair guidance when the installation itself is incomplete.

The full Launcher writes one bounded JSON Lines log per Launcher session under `artifacts/logs/launcher/` and retains the 20 most recent logs. Events time Launcher view construction, catalog discovery, tool probing, App-path preparation, and App invocation. **View Launch Log** renders the current file in a readable window. Durable records contain controlled event names, App commands, durations, outcomes, and error identifiers; they do not retain source paths, data filenames, exception messages, or scientific values. App runtime construction and presentation remain in that App's separate session log.

Every launch uses the same clean App path. Use the App's **Tools > Diagnostics** menu to inspect its live session log. The Session Log window owns manual TRACE capture when additional detail is needed; the structured journal remains under `artifacts/logs/sessions/` after the App closes.

## App Discovery

Public apps are discovered from `apps/**/labkit_*_app.m`. Each entry point delegates to one `definition.m`, which supplies display metadata, family, command, version, requirements, layout, and optional capabilities. The launcher reads version and update metadata from that definition without starting the App. Local private apps may be discovered from `private_apps/apps/` or paths named by `LABKIT_PRIVATE_APP_ROOTS`; their repositories and manuals remain private.

The launcher adds only the paths needed for the selected app. It does not use `genpath` to expose every app helper globally. Refresh the app list after adding, removing, or updating an app while the launcher remains open.

The App catalog is GUI-free and shared with documentation generation. Opening the Launcher is not required to query the catalog or use an App capability. In particular, a popout plot's **Send to Studio** action discovers and starts Figure Studio from the plot boundary; the Launcher does not register a global callback or depend directly on Figure Studio.

## Maintenance Tools

Maintenance buttons are enabled only when their corresponding source-checkout tool is available. The same operations can be called directly from MATLAB:

- [Code Analysis Reports](../../../../develop/tools/codecheck.md)
- [App Deployment Packages](../../../../develop/tools/deployment.md)
- [Documentation Build Tools](../../../../develop/tools/documentation.md)
- [Performance Profiling](../../../../develop/tools/profiling.md)

These tools produce ignored artifacts. They are not app runtime APIs and do not alter scientific data.

## Programmatic Calls

The launcher exposes a small non-GUI surface:

```matlab
fig = labkit_launcher;
apps = labkit_launcher("list");
info = labkit_launcher("version");
page = labkit_launcher("documentation", "labkit_CIC_app");
localPage = labkit_launcher( ...
    "documentation", "labkit_CIC_app", "local");
```

| Call | Result |
| --- | --- |
| `labkit_launcher` | Opens the window; optionally returns its figure handle. |
| `labkit_launcher("list")` | Returns the discovered app catalog as a table without opening the launcher window. |
| `labkit_launcher("version")` | Returns launcher name, display name, semantic version, and update date. |
| `labkit_launcher("documentation", appCommand)` | Returns the online GitHub Pages URL for one discovered public app command. |
| `labkit_launcher("documentation", appCommand, "local")` | Returns the generated local HTML page. The page must already exist; the programmatic call does not display a prompt or generate files. |

Unsupported modes, empty documentation commands, invalid documentation sources, extra inputs, and more than one requested GUI output raise `labkit_launcher:InvalidInput` or `labkit_launcher:TooManyOutputs` errors.

Documentation lookup uses the discovered public App folder and the unique path-conventional manual at `docs/use/apps/<family>/<app>/README.md`. It does not require a separately maintained App catalog. The visible launcher opens online documentation by default. Local generation is an explicit source-checkout convenience: **Doc Generation** always rebuilds the ignored `site/` folder and reports completion without opening a browser. The deployed site is generated independently from `main` by GitHub Actions.

The Launcher and documentation renderer use the same semantic App route resolver. An App guide is generated at `use/apps/<family>/<app>/index.html`, while the online Launcher URL uses the equivalent trailing-slash route. Changing an App documentation path is a hard route change and does not create an alias.

## Installation And Recovery

The downloaded `labkit_launcher.m` can begin by itself. When no installed Launcher is available, it opens a focused install/repair window with:

- an editable installation folder and native **Browse...** action;
- a clear new-installation, existing-installation, or unsafe-target result;
- **Latest stable release** (recommended) or a GitHub-backed selector of published stable Releases;
- honest preparation, download, package-validation, installation, and outcome stages with current-action or error details; and
- confirmation before replacing an existing installation.

The target is checked before any network request. A new install may use a nonexistent folder whose parent exists, an empty folder, or a folder containing only the standalone launcher and ordinary OS metadata. Repair accepts an existing LabKit installation. Filesystem roots, Git checkouts, files, missing parents, and non-LabKit folders containing unrelated content are rejected.

After LabKit is installed, **Latest** and **Versions** in the full Launcher use the same published-Release boundary. Every downloaded archive is validated before replacement. Existing repairs preserve a recovery copy transactionally and retain known local workspace folders when required. Close every running LabKit App before replacing an installation. Standalone repair and the full Launcher's version update workflows refuse to replace LabKit while an App is open, preventing a partial update from disrupting a running session. Keep experimental data and exports outside the runtime folder because installed code is replaceable.

Installed apps run offline unless their own inputs use a network location. Version discovery and update actions require network access. Deployment packages contain MATLAB source; see [App Deployment Packages](../../../../develop/tools/deployment.md).

## Related Documentation

- [Use LabKit](../../../README.md)
- [LabKit Apps](../../README.md)
- [LabKit Core Apps](../README.md)
- [Architecture](../../../../develop/app-authoring/architecture.md)
- [Private Apps](../../../../develop/private-apps.md)
- [Release Process](../../../../develop/release.md)
