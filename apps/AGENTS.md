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
- Do not create app-specific public helper packages to make local workflow code look reusable.
- App-owned private helpers are acceptable only when they stay under the owning app tree and do not become public reusable APIs.
- Callback-heavy migrated apps may use an app-private runner to keep the public
  launcher small, but the runner remains app-owned production code and must not
  become a reusable facade.
- When a public app file grows large, prefer moving GUI-free app-owned calculations, export builders, formatting utilities, and deterministic image/signal transforms into `apps/<family>/<app_slug>/private/`.
- Use `apps/<family>/private/` only for helpers that are genuinely shared by multiple apps in that family.
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
