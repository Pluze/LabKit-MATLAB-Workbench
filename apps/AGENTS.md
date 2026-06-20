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

- Keep domain formulas, thresholds, integration rules, option defaults, plot labels, result fields, export columns, failed-row behavior, alerts, and log wording app-local unless the user explicitly approves a boundary change.
- For a new app cold start, use `labkit_ProjectGovernance_app` interactively or
  `project_governance.ops.createLabKitApp(...)` from MATLAB after
  `startup_labkit(false)`. Do not add MATLAB governance entry points under
  `scripts/`.
- When a documented UI tool owns app-neutral controls or interaction mechanics, consume it instead of reimplementing widget state or normalization. Keep app calculations, summaries, alerts, and exports local.
- Use `labkit.ui.app.create` with `labkit.ui.spec.*` for app GUIs. Do not
  reintroduce the removed `labkit.ui.app.createShell` or legacy view helpers.
- Use `labkit.ui.app.dispatchRequest` for debug launch routing and `labkit.ui.diag.createContext` only when an app has an app-specific nonstandard request path.
- Debug launches should attach the Log tab text area, emit a startup trace line, and instrument high-level component callbacks after controls are built.
- Apps with custom preview scroll, drawing, ROI, scale-bar, or other axes interaction should create a `labkit.ui.tool.createRuntime` and pass that runtime into reusable tools. Do not set preview-tool `WindowScrollWheelFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`, or axes `ButtonDownFcn` directly in app code.
- DTA-backed apps use `labkit.dta.*` for discovery, loading, sessions, pulse detection, and parsed curve/table access.
- RHS-backed apps use `labkit.rhs.*` for discovery, header inspection,
  indexing, and window reads. Channel roles, protocols, event detection,
  nerve response metrics, and exports stay app-owned.
- Biosignal-backed apps use `labkit.biosignal.*` for recording loading, channel extraction, waveform processing, events, segments, measurements, and group comparisons.
- Do not create app-specific helper packages outside the owning app tree, and do not move app-specific helper code into `+labkit`.
- When an app needs extracted helpers, prefer an app-owned package under the app folder. The package name should match the app folder slug, such as `apps/image_measurement/batch_crop/+batch_crop/`.
- New extracted app helper code should use component packages such as `+ui`,
  `+state`, `+ops`, `+view`, `+export`, and `+io` as needed. Do not use a fixed
  `+app` namespace; the app folder already provides ownership context, while a
  shared `+app` package name creates MATLAB package-resolution ambiguity.
- Apps put the ordinary data-only spec in `+<app_slug>/+ui/buildSpec.m`.
  The public app entry point delegates to package-root `run.m`; that runner
  owns state, callback closures, alerts, log wording, and refresh order.
  `buildSpec.m` describes controls, sections, workspace, initial text/defaults,
  and callback handles only.
- Keep nontrivial `buildSpec.m` files readable by showing the app constructor,
  control-tab tree, and workspace at the top, then defining tabs, sections, and
  workspace regions with local builder functions. Prefer this source structure
  over formatter scripts or shared UI templates unless repeated drift proves a
  tool is worth maintaining. Order functions as: `buildSpec`, tab tree,
  tab builders, section builders in visual order, workspace builder, small
  helper builders, then `callbackValue`.
- Do not create MATLAB handles, call `labkit.ui.app.create`, mutate app state,
  perform IO/computation/export, or set `Layout.Row`/`Layout.Column` in
  `+ui/buildSpec.m`. Use named `+ui/build<Thing>.m` custom builders only for
  justified interactions that cannot be expressed with the ordinary spec
  grammar.
- Route helper files by role: `+state` for defaults/factories, `+io` for file
  discovery/readers/filters, `+ops` for GUI-free transforms, `+view` for table
  rows/detail lines/display data, and `+export` for output writers/manifests.
  Do not add boundary-blurring files named `helpers.m`, `utils.m`, `common.m`,
  `misc.m`, `callbacks.m`, `manager.m`, `processor.m`, `layout.m`, or
  `createUI.m`.
- Callback-heavy migrated apps should move app-owned production code into these
  package components instead of adding new `private` runners or string-dispatch
  workflow adapters.
- Use `.agents/migration_guide.md` and the `labkit-migration-planner` skill for
  active runner, app-private, and migration-debt work. This file owns app
  boundary rules, not the migration debt ledger.
- When the wearable ECG Print app is migrated, target
  `apps/wearable/ecg_print/+ecg_print/...` with the public command still named
  `labkit_ECGPrint_app`; do not create a direct `apps/wearable/+ecg_print`
  package.
- Migrated apps use a package-root `run.m` for app lifecycle orchestration.
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
