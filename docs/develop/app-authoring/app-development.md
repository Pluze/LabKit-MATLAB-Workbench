# App Development

```labkit-page
id: develop-build-apps-app-development
type: task
audience: app-developer
summary: Build LabKit apps with app-owned scientific behavior and a small framework-owned lifecycle and user-interface boundary.
```

LabKit apps are first-class deliverables. Each app owns its scientific workflow, state, plots, result schema, and exports; the reusable framework owns lifecycle and domain-neutral UI mechanics.

## Create An App

Start from the LabKit app template rather than copying a complete neighboring app. Use the smallest nearby app only as a workflow example.

A static App begins with only the product entrypoint, definition, and layout it actually uses:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/definition.m
apps/<family>/<app_slug>/+<app_slug>/+workbench/buildLayout.m
```

`labkit.app.Definition` supplies empty scalar state and default presentation behavior when optional components are omitted. Bind real business callbacks directly from the layout. Add `+workbench/present.m` for derived visible state, `CreateState` when the App needs structured runtime data, and `RefreshState` when file-list edits require decoded or cached data to be rebuilt.

Runtime and App architecture names remain versionless. Put facade/App compatibility in the existing version and requirement metadata. Put saved payload numbers only inside an App that explicitly owns a continuation file. Do not create version-named packages, files, functions, types, tests, or manual sections.

An optional state validator owns only App-specific in-memory invariants. The runtime requires a scalar struct and does not impose canonical buckets, durability, migration, or a saved-data schema.

Create additional packages only for concrete workflows that need them, for example `+sourceFiles`, `+analysisRun`, `+resultFiles`, `+cropGeometry`, or `+thermalFrames`. Avoid generic buckets such as `+actions`, `+ops`, `+io`, `+helpers`, and `+utils`.

## Define The Runtime Contract

`definition.m` returns one immutable `labkit.app.Definition`. It is the App's single product contract and names the public command, stable ID, display metadata, App version, compatible LabKit facades, and workbench. State creation, state refresh, presenter, post-layout start callback, and debug sample are opt-in capabilities. Callbacks and renderers are owned directly by their layout nodes.

The complete field tables, callback signatures, state boundary, presenter shape, and renderer contract are documented in [Runtime and Lifecycle](../framework/runtime.md#definition-and-launch). For a complete file-by-file implementation, follow [Build a Complete App](complete-app.md).

The framework owns:

- startup, readiness, and busy state
- queued callback dispatch and rollback
- managed interactions and resources
- unified logging and diagnostic state capture

The app owns all runtime-state meaning, semantic callbacks, presentation models, scientific behavior, final result files, and any explicit continuation archive.

## Build The Workbench

`+workbench/buildLayout.m` returns a data-only `labkit.app.layout.*` tree. Keep tabs, sections, and workspace pages in the same order users see them. For a complex App, compose capability-owned layout fragments instead of flattening every control into this file. It must not create graphics handles, read files, run calculations, mutate state, or schedule startup work.

`+workbench/present.m` is the pure assembly bridge from canonical state to a complete `labkit.app.view.Snapshot`. Compose feature-owned fragments with `Snapshot.include`. Renderers live with the capability they draw, receive only axes and a prepared model, and do not own workflow decisions.

Use the complete runtime value only at this assembly bridge and at callbacks referenced directly by layout signals. Name it `applicationState`, unpack `project` and `session` at the top, and call feature presenters with the exact values they display. A feature presenter should look like `present(results, selection, displayOptions)`, not `present(state)`.

A direct callback is the transaction adapter. Its signature is `(applicationState, callbackContext)` for a button or `(applicationState, typedEventValue, callbackContext)` for a value-bearing signal. It may perform short, visible state mutation in workflow order, then delegate calculations and writes through explicit inputs. Do not pass the complete state or callback context into a generic second action layer.

Classify every input before choosing its callback behavior:

| Input or event | State and presentation timing | Logging |
| --- | --- | --- |
| Slider drag | Native value display only until pointer release | None |
| Rapid paired-spinner edits | Latest native value; one commit after a short quiet interval | None |
| Committed display option | Bind once and rebuild only a bounded current preview | Usually none |
| Committed scientific parameter | Bind once; automatically refresh once when work is bounded, otherwise invalidate stale results and wait for explicit Run | Warning/error only for an exceptional outcome |
| File-list change | Let Runtime bind sources, then rebuild through `RefreshState` | One aggregate outcome when useful; no filenames or paths |
| Stream/device arrival | Buffer outside App state and post one latest-wins semantic refresh | No per-sample log; bounded heartbeat or failure only |
| Run/Generate/Import/Export | One transactional action with delayed busy/progress feedback | Meaningful start/progress/completion or warning/failure boundaries |

Direct manipulation deliberately has no busy display because pointer/title/control flashing is worse than a short synchronous commit. That is a performance contract: slider/spinner callbacks do not perform unbounded or potentially long IO/calculation, export, waiting, polling, pausing, or per-adjustment logging. They may perform one bounded current preview or automatic refresh after the value commits; a navigation control may read one bounded current record or window when that preview is the interaction's core purpose. If the work cannot meet an interactive response budget, move it to an explicit action rather than adding busy chrome to the gesture.

Treat logs as an operational timeline, not a mirror of callback execution. DEBUG is bounded maintainer progress or branch context, INFO is a meaningful user milestone, WARNING is an unexpected recoverable condition requiring attention, ERROR is a failed requested operation, and CRITICAL means the session cannot safely continue. Do not log ordinary value assignments, selection motion, preview repaints, validation success, loop iterations, or every item. Messages and attributes are retained diagnostics: use semantic aliases, counts, dimensions, units, and reasons only; never include paths, original filenames, identities, scientific arrays, or free-form data.

## Name Workflow Code

Use concrete verb-object names such as:

```text
+sourceFiles/readSourceFiles.m
+analysisRun/collectAnalysisOptions.m
+analysisRun/computeAnalysisResults.m
+resultFiles/writeResultFiles.m
```

Keep callback-local glue local when extracting it would hide state mutation or workflow order. Extract a helper when it owns a stable calculation, data shape, file boundary, state transition, or reusable interaction contract. File length alone is not an extraction reason.

## Data Loading And Task Lifecycle

Register large file selections with the least data needed for the first useful preview. Decode the selected file on demand and defer full-batch work until the user runs or exports when the workflow permits it.

When stale or duplicate results are possible, the App owns the smallest explicit last-successful-task or fingerprint state needed by that workflow. Pure helpers build deterministic task snapshots and calculations; result writers receive explicit task data rather than reading UI handles. Do not add generic dirty state or document identity for Apps that do not continue a task.

## Cross-App Data Contracts

Apps exchange a saved data contract only when a real workflow consumes it; production and test setup do not call a sibling App package merely to create inputs. A consumer owns its parser and error language, so it can launch with only the framework and its own App root on the MATLAB path. A producer owns serialization and schema validation. Test the current producer-consumer contract directly when that connection exists; do not invent a common archive, fixture protocol, or compatibility matrix for unrelated Apps.

## Ownership Check

Keep these in the app:

- accepted formats, domain defaults, units, and thresholds
- formulas and scientific interpretation
- plots, labels, result columns, and export schemas
- workflow ordering, user messages, and logs

Move code into `+labkit` only when it is domain-neutral, independent of app state, directly testable, used broadly, and makes the public API clearer. See [Architecture](architecture.md#reusable-extraction-rule).

## Version And Requirements

`definition.m` owns supported LabKit facade ranges together with the App command, display name, family, semantic version, and last change date. There is no second metadata registry. App behavior changes update this definition, the App documentation, and component-owned history in the same coherent change.

## Validation

Use focused app tests while editing, then follow the stable gates in [Testing](../testing.md). Automated GUI tests cover launch, layout, callbacks, debug plumbing, and bounded workflows with minimal generated inputs; visual quality and manual interaction feel still require a human MATLAB check.

## Related Reference

- [App catalog and workflows](../../use/apps/README.md)
- [App Framework](../framework/README.md)
- [Architecture](architecture.md)
- [Testing](../testing.md)
