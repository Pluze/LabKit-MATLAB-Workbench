# Apps Agent Rules

Apps are first-class deliverables. Do not treat them as examples for a hidden platform.

## Read Before Editing

- `docs/apps.md`
- `docs/ui.md` for layout, controls, axes, callbacks, or app shell changes
- `docs/dta.md` for DTA-backed apps
- `docs/biosignal.md` for wearable or biosignal-backed apps
- affected app tests under `tests/unit/apps/` or `tests/gui/structural/apps/`

## App Ownership

- Keep domain formulas, thresholds, integration rules, option defaults, plot labels, result fields, export columns, failed-row behavior, alerts, and log wording app-local unless the user explicitly approves a boundary change.
- When a documented UI tool owns app-neutral controls or interaction mechanics, consume it instead of reimplementing widget state or normalization. Keep app calculations, summaries, alerts, and exports local.
- Use `labkit.ui.app.create` with `labkit.ui.spec.*` for new or migrated app
  GUIs. Unmigrated apps may continue to use `labkit.ui.app.createShell` until
  their UI 2.0 migration lands.
- Use `labkit.ui.app.dispatchRequest` for debug launch routing and `labkit.ui.diag.createContext` only when an app has an app-specific nonstandard request path.
- Debug launches should attach the Log tab text area, emit a startup trace line, and instrument high-level component callbacks after controls are built.
- Image apps with custom preview scroll, drawing, ROI, scale-bar, or other axes interaction should create a `labkit.ui.tool.createRuntime` and pass that runtime into reusable tools. Do not set image-tool `WindowScrollWheelFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`, or axes `ButtonDownFcn` directly in app code.
- DTA-backed apps use `labkit.dta.*` for discovery, loading, sessions, pulse detection, and parsed curve/table access.
- Biosignal-backed apps use `labkit.biosignal.*` for recording loading, channel extraction, waveform processing, events, segments, measurements, and group comparisons.
- Do not create app-specific helper packages outside the owning app tree, and do not move app-specific helper code into `+labkit`.
- When an app needs extracted helpers, prefer an app-owned package under the app folder. The package name should match the app folder slug, such as `apps/image_measurement/batch_crop/+batch_crop/`.
- New extracted app helper code should use component packages such as `+ui`,
  `+state`, `+ops`, `+view`, `+export`, and `+io` as needed. Do not use a fixed
  `+app` namespace; the app folder already provides ownership context, while a
  shared `+app` package name creates MATLAB package-resolution ambiguity.
- UI 2.0 migrated apps should put the ordinary data-only spec in
  `+<app_slug>/+ui/buildSpec.m`. The public app entry point, or the app-owned
  orchestration runner it delegates to when the public file is a thin dispatch
  wrapper, owns state, callback closures, alerts, log wording, and refresh
  order; `buildSpec.m` describes controls, sections, workspace, initial
  text/defaults, and callback handles only.
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
  active runner, app-private, and migration-roadmap work. This file owns app
  boundary rules, not the full migration playbook.
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
- Do not add new `apps/<family>/private/` helpers unless the helper is genuinely shared by multiple apps in that family and the user approves that family-level boundary.
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
