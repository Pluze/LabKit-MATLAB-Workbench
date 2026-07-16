# Apps Agent Rules

Apps are first-class deliverables. Do not treat them as examples for a hidden platform.

## Read Before Editing

- `docs/apps/README.md` for current user workflows
- `docs/development/app-development.md` for app structure and authoring
- `docs/api/ui.md` for layout, controls, axes, callbacks, or app shell changes
- `docs/api/dta.md` for DTA-backed apps
- `docs/api/rhs.md` for RHS-backed apps
- `docs/libraries/biosignal/README.md` for wearable or biosignal-backed apps
- affected app tests under `tests/cases/unit/apps/` or `tests/cases/gui/apps/`

## App Ownership

- Apps follow the root dependency boundary: do not add package-manager setup,
  Python environments, third-party runtime libraries, downloaded model
  weights, or network-installed inference assets. Additional MathWorks product
  use must be deliberate, visible in app behavior or requirements, and must
  not trigger installation from an app callback.
- A rapid-development MathWorks Toolbox path is temporary debt, not the app's
  only implementation. Ship and directly test a comparable base-MATLAB path,
  keep the Toolbox symbol visible to dependency analysis, register fallback,
  idempotency, and parity tests through `labkitToolboxDebt`, and point its ledger record at the planned
  repository-owned replacement. Availability checks must select a working
  fallback; they must not conceal the dependency from guardrails.
- App-owned numeric or scientific replacements must be idempotent for repeated
  identical inputs: pure calculations return the same app-consumed values, and
  stateful operations do not accumulate state or side effects when safely
  repeated. Their parity tests compare the values
  the app actually consumes, including any downstream decision or export
  fields, against the Toolbox reference with a documented tolerance.
- Keep domain formulas, thresholds, integration rules, option defaults, plot labels, result fields, export columns, failed-row behavior, alert wording/trigger decisions, and log wording app-local unless the user explicitly approves a boundary change.
- Private apps under `private_apps/apps/` or `LABKIT_PRIVATE_APP_ROOTS` should
  follow the same app-owned package shape as public apps, but their app
  details, tests, docs, and release notes belong in the private workspace repo.
  Do not copy private app details into public docs or public tests.
- For a new app cold start, use the LabKit app template/scaffold when
  available. App authors should primarily edit one app-owned MATLAB package
  with a small fixed lifecycle/UI surface and concrete workflow packages:
  `apps/<family>/<app_slug>/+<app_slug>/definition.m`,
  `apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createProject.m`,
  `apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createSession.m`,
  `apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/validateProject.m`,
  `apps/<family>/<app_slug>/+<app_slug>/+userInterface/buildWorkbenchLayout.m`,
  `apps/<family>/<app_slug>/+<app_slug>/+userInterface/presentWorkbench.m`,
  and app-specific workflow packages such as
  `apps/<family>/<app_slug>/+<app_slug>/+appState/exportPlan.m`,
  `apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/readSourceFiles.m`,
  `apps/<family>/<app_slug>/+<app_slug>/+analysisRun/computeAnalysisResults.m`,
  or `apps/<family>/<app_slug>/+<app_slug>/+resultFiles/writeResultFiles.m`.
  Use the smallest genuinely similar app only as a workflow reference, not as a
  directory tree to copy.
- When a documented UI tool owns app-neutral controls or interaction mechanics, consume it instead of reimplementing widget state or normalization. Keep app calculations, summaries, alert text, and exports local.
- Use `labkit.ui.runtime.define` and the standard
  `labkit.ui.runtime.launch` entrypoint with `labkit.ui.layout.*` for app GUIs.
  `labkit.ui.runtime.create` is framework implementation, not app lifecycle
  orchestration. Do not reintroduce removed shell or legacy view helpers.
- Let `labkit.ui.runtime.launch` own normal/debug/requirements/version routing,
  runtime construction, outputs, and the version title. Use lower-level
  dispatch or debug context APIs only for a proven nonstandard request such as
  an in-memory handoff that the standard launch contract cannot express.
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
- App code must not create startup timers, loading strips, readiness flags, or
  lifecycle mutation APIs. Optional initial domain work is one queued `Start`
  handler declared in `definition.m`.
- App alerts call `services.dialogs.alert(message, titleText)`. Apps still own
  the title, message, and decision; the framework owns modal mechanics.
- Apps express preview scroll, drawing, ROI, scale-bar, and other axes
  interactions as presenter-owned controlled interaction specs. Do not create
  interaction runtimes or set figure/axes callbacks directly.
- DTA-backed apps use `labkit.dta.*` for discovery, loading, pulse detection, and parsed curve/table access. Task queues, duplicate policy, current selection, analysis state, and export workflow stay app-owned.
- RHS-backed apps use `labkit.rhs.*` for discovery, header inspection,
  indexing, and window reads. Channel roles, protocols, event detection,
  nerve response metrics, and exports stay app-owned.
- Biosignal-backed apps use `labkit.biosignal.*` for recording loading, channel extraction, waveform processing, events, segments, measurements, and group comparisons.
- Image-backed apps use `labkit.image.*` for generic source-image filters,
  path normalization, display names, reads/writes, RGB double conversion,
  preview resizing, mean filtering, and basic enhancement primitives. Interaction
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
- Handler file dialogs outside `filePanel` use injected `services.dialogs`
  instead of raw MATLAB dialogs, `pwd`, or bare output filenames.
- Project, snapshot, manifest, and autosave imports that contain external file
  fields must store `labkit.ui.runtime.createPortableFileReference` values and
  resolve each field through `resolveOrPromptForFileReference`. Missing or
  malformed saved paths must offer manual relinking with a field-specific
  label; do not silently clear the field or make an old absolute path the only
  recovery route. Apps still validate the selected file's format and content.
- Do not create app-specific helper packages outside the owning app tree, and do not move app-specific helper code into `+labkit`.
- When an app needs extracted helpers, prefer an app-owned package under the app folder. The package name should match the app folder slug, such as `apps/image_measurement/batch_crop/+batch_crop/`.
- New extracted app helper code should use concrete workflow packages named
  after the user-facing capability they own, such as `+sourceFiles`,
  `+analysisRun`, `+cropGeometry`, `+thermalFrames`, or `+resultFiles`. Do not
  use broad technical buckets such as `+actions`, `+renderers`, `+ops`, `+io`,
  or `+export` for new app code; those split one workflow across overlapping
  folders. Do not use a fixed `+app` namespace; the app folder already provides
  ownership context, while a shared `+app` package name creates MATLAB
  package-resolution ambiguity.
- Apps expose their runtime declaration through `+<app_slug>/definition.m`,
  durable and transient state through `+appLifecycle/createProject.m` and
  `createSession.m`, project checks through `validateProject.m`, UI declaration
  through `+userInterface/buildWorkbenchLayout.m`, presentation through
  `+userInterface/presentWorkbench.m`, deterministic app-state and
  task snapshot helpers through `+appState`, and user workflows through
  concrete app-owned packages. Do not reintroduce `+state`, `+actions`, `+ui`,
  `+view`, `+ops`, `+io`, or `+export` packages.
- `definition.m` declares identity, project schema, optional session factory,
  layout builder, handler registry, presenter, renderers, and optional `Start`.
  It must not create MATLAB handles, read files,
  compute results, export data, or mutate framework lifecycle state.
- `+userInterface/buildWorkbenchLayout.m` describes controls, sections,
  workspace, initial text/defaults, and framework-generated callback handles
  only. Do not add legacy `+ui/buildSpec.m` or replacement `+ui/buildLayout.m`
  adapters.
- Package-root `run.m` lifecycle orchestration has been retired. Do not add
  eager package-root app runners or compatibility shims.
- Do not treat the repository line budget as a request to split every small
  action, label formatter, boolean check, or one-call framework wrapper into a
  separate file. Use `.agents/migration_guide.md` to decide which cohesive
  responsibility should move.
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
- Keep nontrivial layout builders readable by showing the app constructor,
  control-tab tree, and workspace at the top, then defining tabs, sections, and
  workspace regions with local builder functions. Prefer this source structure
  over formatter scripts or shared UI templates unless repeated drift proves a
  tool is worth maintaining. Order functions as: `buildWorkbenchLayout`, tab
  tree, tab builders, section builders in visual order, workspace builder,
  small helper builders, then `callbackValue`.
- Do not create MATLAB handles, call `labkit.ui.runtime.create`, mutate app state,
  perform IO/computation/export, set `Layout.Row`/`Layout.Column`, or pass
  concrete layout props such as `height`, `minRows`, `minHeight`, `maxColumns`,
  `rowSpacing`, `columnSpacing`, `padding`, `chrome`, `columnWidth`,
  `rowHeight`, `position`, or `leftWidth` in app UI layout builders. Apps may
  declare tabs, sections, control order, semantic values, and callbacks; the
  LabKit framework owns concrete layout. When an app needs a control that
  cannot be expressed with the ordinary layout nodes, add a named
  framework/app layout or interaction contract instead of custom layout code.
- Route helper files by workflow capability, not by broad technical role. A
  package such as `apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/` may own
  choosing files, reading files, validating source state, and showing source
  previews because those functions change together. A package such as
  `apps/<family>/<app_slug>/+<app_slug>/+resultFiles/` may own result-folder
  choice, output writes, manifests, and export summaries for the same reason.
  Do not mix file and folder forms for the same concept, such as
  `sourceFiles.m` plus `+sourceFiles/`. Avoid abstract bucket names such as
  `actions.m`, `view.m`, `render.m`, `manager.m`, and `processor.m`.
  Do not add boundary-blurring files named `helpers.m`, `utils.m`, `common.m`,
  `misc.m`, `callbacks.m`, `manager.m`, `processor.m`, `layout.m`, or
  `createUI.m`.
- Callback-heavy apps should move app-owned production code into concrete
  workflow packages instead of adding new `private` runners or string-dispatch
  workflow adapters.
- For apps with a preview-edit-export workflow, keep preview computation
  separate from export computation. Preview callbacks should operate only on
  the current selection and on display-resolution data when practical; Apply
  commands should record user workflow state or history instead of processing
  every loaded file; Export commands should be the batch boundary that processes
  original-resolution inputs. Do not maintain full-resolution batch result
  caches solely to make previews responsive. When downsampled previews apply
  operations with pixel-unit parameters such as radius or window size, scale
  those parameters to the preview resolution so preview behavior remains
  comparable to original-resolution export.
- File chooser commands should register paths and load only the data needed
  for the immediate visible state. Do not read, parse, calibrate, or compute
  every selected file in the selection command unless the app cannot render a
  useful first state without the full batch. Put path-only item factories in
  the workflow package that owns the selected files, keep lazy load/refresh
  order in that workflow plus `+userInterface/presentWorkbench.m`, and
  add a unit or GUI regression that proves large selections stay deferred.
- Apps with preview, run, or export task lifecycles should build immutable
  app-owned task snapshots in the workflow package that owns the task and
  compare deterministic fingerprints before repeated work. The runtime may own
  dirty flags, small preview caches, and last-successful fingerprints;
  computation and result-file helpers should stay GUI-free and testable. Do
  not promote app task semantics into `+labkit` until at least two apps prove
  the same neutral abstraction is needed.
- Use `.agents/migration_guide.md` and the `labkit-migration-planner` skill for
  active runner, app-private, and migration-debt work. This file owns app
  boundary rules, not the migration debt ledger.
- Apps use `definition.m` plus the framework runtime for lifecycle
  orchestration. Keep `+userInterface` focused on workbench layouts, visible
  presentation models, prepared renderers, and justified tool/widget glue; do not put
  app lifecycle runners in UI packages.
- Do not add new `*Workflow.m` files or app-owned `+core/dispatch.m` string
  routers.
- When a public app file grows large, prefer moving GUI-free app-owned
  calculations, result-file builders, formatting utilities, deterministic
  image/signal transforms, and focused control construction into concrete
  workflow packages under `apps/<family>/<app_slug>/+<app_slug>/...`.
- Do not add new `apps/<family>/private/` helpers. Keep helpers in the owning
  app package, or use `labkit-boundary-guard` before promoting genuinely
  reusable behavior into `+labkit`.
- Keep the public app entry point as a thin launch wrapper. App definitions,
  workflow packages, and UI update helpers own GUI state, user alerts, app
  workflow order, and user-facing log wording. The framework owns debug launch
  routing, callback generation, readiness, busy gating, and lifecycle
  scheduling.

## Documentation Sync

- User-facing app behavior changes update `README.md` when advertised there and `docs/apps/README.md` for current app behavior.
- App ownership, entrypoint, or workflow-boundary rule changes update this file.
- Keep internal test/debug hook details out of README.
- Do not update this file for app implementation changes that preserve the app ownership and workflow-boundary rules; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.

## Validation Routing

Route validation by the touched app family and whether the change affects pure
logic/export behavior, layout/callback wiring, or app-entrypoint boundaries.
Use `docs/development/testing.md` for exact task names and pairings. App entrypoint,
ownership-boundary, fixture, or validation-rule changes should include the
project guardrail task.
