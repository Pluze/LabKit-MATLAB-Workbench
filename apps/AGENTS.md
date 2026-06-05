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
- Use `labkit.ui.app.createShell` for app GUIs.
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
- Callback-heavy migrated apps should move app-owned production code into these
  package components instead of adding new `private/` runners or string-dispatch
  workflow adapters.
- When a public app file grows large, prefer moving GUI-free app-owned calculations, export builders, formatting utilities, deterministic image/signal transforms, and focused control construction into `apps/<family>/<app_slug>/+<app_slug>/...`.
- Do not add new `apps/<family>/private/` helpers unless the helper is genuinely shared by multiple apps in that family and the user approves that family-level boundary.
- Keep the public app entry point responsible for GUI state, callbacks, user alerts, app workflow order, debug launch routing, and user-facing log wording.

## Documentation Sync

- User-facing app behavior changes update `README.md` when advertised there and `docs/apps.md` for current app behavior.
- App ownership, entrypoint, or workflow-boundary rule changes update this file.
- Keep internal test/debug hook details out of README.
- Do not update this file for app implementation changes that preserve the app ownership and workflow-boundary rules; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.

## Validation Routing

- Electrochem app change: `buildtool testAppsElectrochem`; use
  `buildtool testAppsElectrochemGui` for layout, launch, or callback wiring.
- DIC app change: `buildtool testAppsDicGui`.
- Image measurement app change: `buildtool testAppsImageMeasurement`; use
  `buildtool testAppsImageMeasurementGui` for layout, launch, or callback wiring.
- Wearable app change: `buildtool testAppsWearableGui`; add
  `buildtool testLabkitBiosignal` when the biosignal facade contract may be
  affected.
- App entrypoint or boundary changes also run `buildtool testProject`.
