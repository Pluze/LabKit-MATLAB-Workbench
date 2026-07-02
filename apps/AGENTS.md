# Apps Agent Rules

Apps are first-class deliverables. Do not treat them as examples for a hidden platform.

## Read Before Editing

- `docs/apps.md`
- `docs/ui.md` for layout, controls, axes, callbacks, or app shell changes
- `docs/dta.md` for DTA-backed apps
- `docs/rhs.md` for RHS-backed apps
- `docs/biosignal.md` for wearable or biosignal-backed apps
- affected app tests under `tests/cases/unit/apps/` or `tests/cases/gui/apps/`

## App Ownership

- Keep domain formulas, thresholds, integration rules, option defaults, plot labels, result fields, export columns, failed-row behavior, alert wording/trigger decisions, and log wording app-local unless the user explicitly approves a boundary change.
- For a new app cold start, create the standard app shape directly and use the
  smallest genuinely similar app as a reference. Keep the first version focused
  on the real workflow rather than placeholder behavior.
- When a documented UI tool owns app-neutral controls or interaction mechanics, consume it instead of reimplementing widget state or normalization. Keep app calculations, summaries, alert text, and exports local.
- Use `labkit.ui.app.create` with `labkit.ui.spec.*` for app GUIs. Do not
  reintroduce the removed `labkit.ui.app.createShell` or legacy view helpers.
- Use `labkit.ui.app.dispatchRequest` for debug launch routing and `labkit.ui.diag.createContext` only when an app has an app-specific nonstandard request path.
- Each public app entrypoint should call app package `requirements.m` and
  `version.m`, pass both structs to `labkit.ui.app.dispatchRequest`, and apply
  the version title after `run.m` returns the figure. Lightweight non-GUI
  requests are `"requirements"` and `"version"`.
- App package `requirements.m` must return the result of
  `labkit.contract.requirements(...)`. Do not return a plain struct, map, or
  app-authored schema; launch dispatch rejects anything whose `type` is not
  `"labkit.requirements"`.
- App package `version.m` must return scalar text fields named exactly
  `name`, `displayName`, `family`, `version`, and `updated`. The `name` field
  is the public app entrypoint function, such as `labkit_FocusStack_app`, not
  the human display name. Use `X.Y.Z` for `version` and `YYYY-MM-DD` for
  `updated`.
- When app source, app-owned package code, or app-facing behavior changes,
  update that app's `version.m` version metadata before merge or direct `main`
  push. Feature-branch migration work may use small commits without bumping
  the version each time; make the aggregate bump once before squash or handoff,
  choosing the next `X.Y.Z` value from the latest `main` version file.
- Debug launches should attach the Log tab text area, emit a startup trace line, and instrument high-level component callbacks after controls are built.
- App callbacks that catch `MException` and continue must call
  `debug.reportException(component, event, ME)` before showing an alert,
  logging a recovery message, or returning. Do not swallow import, export,
  preview, or tool errors without a framework debug/crash report.
- App alerts must call `labkit.ui.app.showAlert(fig, message, titleText)`
  instead of raw `uialert`. Apps still own the title, message, and decision to
  alert; the framework owns hidden-test-safe modal mechanics.
- Apps with custom preview scroll, drawing, ROI, scale-bar, or other axes interaction should create a `labkit.ui.tool.createRuntime` and pass that runtime into reusable tools. Do not set preview-tool `WindowScrollWheelFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`, or axes `ButtonDownFcn` directly in app code.
- DTA-backed apps use `labkit.dta.*` for discovery, loading, pulse detection, and parsed curve/table access. Task queues, duplicate policy, current selection, analysis state, and export workflow stay app-owned.
- RHS-backed apps use `labkit.rhs.*` for discovery, header inspection,
  indexing, and window reads. Channel roles, protocols, event detection,
  nerve response metrics, and exports stay app-owned.
- Biosignal-backed apps use `labkit.biosignal.*` for recording loading, channel extraction, waveform processing, events, segments, measurements, and group comparisons.
- Image-backed apps use `labkit.image.*` for generic source-image filters,
  path normalization, display names, reads/writes, RGB double conversion,
  preview resizing, mean filtering, and basic enhancement primitives. Tool
  lists, ROI/background policy, reference matching, crop geometry, focus-stack
  algorithms, DIC behavior, export schemas, and user-facing workflow text stay
  app-owned.
- Thermal-image apps use `labkit.thermal.*` for radiometric source parsing,
  raw thermal matrices, embedded calibration metadata, raw-to-temperature
  conversion, thermal palette rendering, and compatibility inspection. Mixed
  file selections should use `labkit.thermal.inspectFile` or
  `labkit.thermal.readFiles(..., struct("SkipInvalid", true))`; do not
  reimplement "is this thermal" detection in app-local catch blocks. File
  queues, display-range defaults, export manifests, colorbar placement,
  overlay-removal workflow wording, measurements, alerts, and logs stay
  app-owned.
- App-local file dialogs that remain outside `filePanel` must use
  `labkit.ui.app.defaultDialogFolder("input")` or `"output"` instead of `pwd`
  or bare output filenames.
- Do not create app-specific helper packages outside the owning app tree, and do not move app-specific helper code into `+labkit`.
- When an app needs extracted helpers, prefer an app-owned package under the app folder. The package name should match the app folder slug, such as `apps/image_measurement/batch_crop/+batch_crop/`.
- New extracted app helper code should use component packages such as `+ui`,
  `+state`, `+ops`, `+view`, `+export`, and `+io` as needed. Do not use a fixed
  `+app` namespace; the app folder already provides ownership context, while a
  shared `+app` package name creates MATLAB package-resolution ambiguity.
- Apps put the ordinary data-only spec in `+<app_slug>/+ui/buildSpec.m`.
  The public app entry point delegates to package-root `run.m`; that runner
  owns state, callback closures, alert wording, log wording, and refresh order.
  `buildSpec.m` describes controls, sections, workspace, initial text/defaults,
  and callback handles only.
- Package-root `run.m` files are allowed to contain app lifecycle
  orchestration. Do not treat the repository line budget as a request to split
  every small callback, label formatter, boolean check, or one-call framework
  wrapper into a separate file.
- Treat roughly 500 lines in `run.m` as a responsibility-review threshold,
  roughly 625 lines as a migration threshold, and the repository file budget as
  only the hard backstop. Near those thresholds, use
  `.agents/migration_guide.md` to decide which cohesive responsibility should
  move, not how many helper files to create.
- Before extracting a new app helper, name the contract it owns: deterministic
  state shape, IO normalization, file discovery, GUI-free operation, export
  boundary, display data, or focused custom UI/tool glue. A helper that only
  exists to make the line count smaller should stay local, inline, or nested.
- Helpers under roughly 20 lines need a clear reason to live in their own file:
  stable app data shape, multiple meaningful call sites, direct tests, public
  facade role, or an allowed small factory/filter/default contract. Otherwise
  keep the code near the caller so workflow order and state mutation stay easy
  to read.
- When reducing a dense runner, also audit recently extracted micro-helpers.
  Inline or merge short helpers that obscure the call site and have no
  independent contract; extract larger cohesive blocks that remove a real
  responsibility from the runner.
- Keep nontrivial `buildSpec.m` files readable by showing the app constructor,
  control-tab tree, and workspace at the top, then defining tabs, sections, and
  workspace regions with local builder functions. Prefer this source structure
  over formatter scripts or shared UI templates unless repeated drift proves a
  tool is worth maintaining. Order functions as: `buildSpec`, tab tree,
  tab builders, section builders in visual order, workspace builder, small
  helper builders, then `callbackValue`.
- Do not create MATLAB handles, call `labkit.ui.app.create`, mutate app state,
  perform IO/computation/export, set `Layout.Row`/`Layout.Column`, or pass
  concrete layout props such as `height`, `minRows`, `minHeight`, `maxColumns`,
  `rowSpacing`, `columnSpacing`, `padding`, `chrome`, `columnWidth`,
  `rowHeight`, `position`, or `leftWidth` in `+ui/buildSpec.m`. Apps may
  declare tabs, sections, control order, semantic values, and callbacks; the
  LabKit framework owns concrete layout. When an app needs a control that
  cannot be expressed with the ordinary spec grammar, add a named spec/tool
  contract instead of custom layout code.
- Route helper files by role: `+state` for defaults/factories, `+io` for file
  discovery/readers/filters, `+ops` for GUI-free transforms, `+view` for table
  rows/detail lines/display data, and `+export` for output writers/manifests.
  Do not add boundary-blurring files named `helpers.m`, `utils.m`, `common.m`,
  `misc.m`, `callbacks.m`, `manager.m`, `processor.m`, `layout.m`, or
  `createUI.m`.
- Callback-heavy apps should move app-owned production code into these
  package components instead of adding new `private` runners or string-dispatch
  workflow adapters.
- For apps with a preview-edit-export workflow, keep preview computation
  separate from export computation. Preview callbacks should operate only on
  the current selection and on display-resolution data when practical; Apply
  actions should record user workflow state or history instead of processing
  every loaded file; Export actions should be the batch boundary that processes
  original-resolution inputs. Do not maintain full-resolution batch result
  caches solely to make previews responsive. When downsampled previews apply
  operations with pixel-unit parameters such as radius or window size, scale
  those parameters to the preview resolution so preview behavior remains
  comparable to original-resolution export.
- File chooser callbacks should register paths and load only the data needed
  for the immediate visible state. Do not read, parse, calibrate, or compute
  every selected file in the selection callback unless the app cannot render a
  useful first state without the full batch. Put path-only item factories in
  app-owned `+state`, keep lazy load/refresh order in the runner, and add a
  unit or GUI regression that proves large selections stay deferred.
- Apps with preview, run, or export task lifecycles should build immutable
  app-owned task snapshots in `+state` and compare deterministic fingerprints
  before repeated work. The runner may own dirty flags, small preview caches,
  and last-successful fingerprints; `+ops` and `+export` should stay GUI-free
  and testable. Do not promote app task semantics into `+labkit` until at
  least two apps prove the same neutral abstraction is needed.
- Use `.agents/migration_guide.md` and the `labkit-migration-planner` skill for
  active runner, app-private, and migration-debt work. This file owns app
  boundary rules, not the migration debt ledger.
- Apps use a package-root `run.m` for app lifecycle orchestration.
  Keep `+ui` focused on `buildSpec.m`, UI handle mapping, and justified
  tool/widget glue; do not put app lifecycle runners in `+ui/runApp.m`.
- Do not add new `*Workflow.m` files or app-owned `+core/dispatch.m` string
  routers.
- When a public app file grows large, prefer moving GUI-free app-owned calculations, export builders, formatting utilities, deterministic image/signal transforms, and focused control construction into `apps/<family>/<app_slug>/+<app_slug>/...`.
- Do not add new `apps/<family>/private/` helpers. Keep helpers in the owning
  app package, or use `labkit-boundary-guard` before promoting genuinely
  reusable behavior into `+labkit`.
- Keep the public app entry point as a thin launch wrapper. The package-root
  `run.m` owns GUI state, callbacks, user alerts, app workflow order, debug
  launch routing, and user-facing log wording.

## Documentation Sync

- User-facing app behavior changes update `README.md` when advertised there and `docs/apps.md` for current app behavior.
- App ownership, entrypoint, or workflow-boundary rule changes update this file.
- Keep internal test/debug hook details out of README.
- Do not update this file for app implementation changes that preserve the app ownership and workflow-boundary rules; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.

## Validation Routing

Route validation by the touched app family and whether the change affects pure
logic/export behavior, layout/callback wiring, or app-entrypoint boundaries.
Use `docs/testing.md` for exact task names and pairings. App entrypoint,
ownership-boundary, fixture, or validation-rule changes should include the
project guardrail task.
