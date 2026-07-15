# +labkit Agent Rules

`+labkit` is a small reusable library, not a dumping ground.

## Read Before Editing

- `docs/development/architecture.md`
- `docs/api/ui.md` for `+labkit/+ui`
- `docs/api/image.md` for `+labkit/+image`
- `docs/api/thermal.md` for `+labkit/+thermal`
- `docs/api/dta.md` for `+labkit/+dta`
- `docs/api/rhs.md` for `+labkit/+rhs`
- `docs/api/biosignal.md` for `+labkit/+biosignal`
- affected package tests under `tests/cases/unit/labkit/` or `tests/cases/gui/labkit/`

## Boundary Rules

- Public API growth must be conservative.
- New public helpers must be domain-neutral, independently testable, useful beyond one workflow, and clearer as an API than as app-local code.
- When replacing a MATLAB toolbox function with a base-MATLAB implementation,
  use the MATLAB function name and preserve its documented call contract under
  the owning `labkit.*` namespace. Keep orthogonal shaping or validation steps
  in explicitly named helpers; do not bundle them into convenience APIs such
  as `toRgbDouble` that silently combine conversion, channel changes, and
  clipping.
- Do not encode experiment-specific units, thresholds, result columns, plot wording, or export schemas in reusable helpers.
- Do not add public `+labkit/+analysis`, `+data`, `+io`, or `+util` app-facing surfaces.
- `labkit.dta` stays GUI-free and app-free.
- `labkit.rhs` stays GUI-free, app-free, and protocol-neutral. It may parse
  RHS file metadata and waveform windows, but it must not encode stimulus
  trains, nerve channel roles, CAP thresholds, segment schemas, or exports.
- `labkit.biosignal` stays GUI-free and independent from DTA/app code.
- `labkit.image` stays GUI-free and owns only generic image file IO,
  display normalization, resizing, mean filtering, and basic enhancement
  primitives. It must not encode app tool histories, ROI/background policy,
  reference-match workflows, crop/export schemas, focus-stack algorithms, DIC
  behavior, or user-facing workflow text.
- `labkit.thermal` stays GUI-free and app-free. It owns thermal source-file
  parsing, raw thermal matrices, embedded calibration metadata,
  raw-to-temperature conversion, thermal colormap rendering, and
  compatibility inspection for mixed file selections. It must not own app file
  queues, display-range defaults, export manifests, overlay-removal workflow
  text, measurement decisions, or vendor-specific UI wording.
- `labkit.ui` stays parser/data/analysis-free; apps pass prepared values, labels, tables, callbacks, and handles into UI helpers.
- `labkit.contract` owns only MATLAB-native facade contract structs, simple range
  checks, and app requirement assertions. It must stay domain-neutral and must
  not become a package manager, plugin registry, or app metadata store.
- App version display belongs to app-owned `version.m` files plus
  `labkit.ui.runtime` title formatting; do not move app metadata into
  `labkit.contract` or a central registry.
- When app-facing facade code changes under `+labkit/+ui`, `+image`, `+thermal`, `+dta`,
  `+rhs`, or `+biosignal`, update the owning facade `version()` contract before
  merge or direct `main` push. Feature-branch migration work may use small
  commits without bumping the version each time; make the aggregate bump once
  before squash or handoff, choosing the next `X.Y.Z` value from the latest
  `main` version file.
- Reusable UI tools may own domain-neutral interaction workflows such as image scale-bar controls, reference editing, unit normalization, and overlay placement. Keep those tools independent from app result schemas, scientific formulas, file formats, and workflow wording.
- App-facing UI APIs live under `labkit.ui.runtime.*`, `labkit.ui.layout.*`,
  `labkit.ui.plot.*`, `labkit.ui.interaction.*`, and `labkit.ui.debug.*`.
  Control mutation and registry access are runtime-private; do not reintroduce
  `labkit.ui.control.*`, flat `labkit.ui.*` helpers, or the retired
  `app/spec/view/tool/diag` package names.
- `labkit.ui.runtime` owns the declarative app runtime: app definition validation,
  generated semantic callbacks, startup readiness, busy gating, staged
  hydration, close guards, debug exception routing, and startup phase timing.
  Public app-facing runtime growth should favor stable definition/launch
  contracts. Keep `create` as a low-level framework construction surface; app
  entry points use `launch`. Do not expose raw startup timers,
  loading controls, readiness flags, or `defer/update/finish` lifecycle
  mutation helpers to app code.
- Runtime V2 uses `labkit.ui.runtime.launch` plus the V2 `define` contract.
  Apps use canonical project/session state,
  queued events, `Present`, registered renderers, and managed resources. Do
  not expose the v2 private queue, store, presentation, or resource-registry
  helpers as public APIs.
- Runtime V2 presentation commits must not invoke unchanged preview requests.
  Preserve existing graphics and viewports for state-only events; app renderers
  own incremental overlay updates when their model changes but the background
  data remains the same.
- Runtime v2 owns one private figure interaction hub. V2 apps declare
  controlled interaction specs from `Present` and must not construct a second
  interaction runtime or restore figure callbacks.
- Runtime v2 persistence keeps document metadata outside semantic state,
  writes only the project allowlist through the `labkitProject` codec, and
  replaces project plus a fresh session only after migration, validation, and
  source resolution succeed. Keep explicit save, recovery, and result-export
  storage mechanics private; app handlers use runtime services and may declare
  app-owned ordered migrations, resume application, and legacy import/relink
  hooks without adding app-id branches under `+labkit`.
- Interaction callbacks must keep user-facing semantic callbacks separate from internal refresh/sync callbacks, no-op when a setter receives the current value, and trace callback reason/source when a tool exposes debug trace.
- Debug traces are diagnostic probes for GUI interaction failures, callback errors, stalled file loads, and environment-sensitive launch problems; do not turn them into workflow narration or log sensitive paths/data.
- Debug contexts own framework crash reports, active-operation files, and
  caught-exception reporting. Keep report fields app-neutral and sanitized;
  apps should pass caught `MException` values through `debug.reportException`
  rather than inventing app-local report formats.
- Do not introduce MATLAB classes unless explicitly approved.

## Comments and Docs

- Public functions under `+labkit/+ui`, `+labkit/+image`, `+labkit/+thermal`, `+labkit/+dta`, `+labkit/+rhs`, and `+labkit/+biosignal` must document app-facing call contracts immediately after the function declaration.
- Private helpers must document expected caller, input/output shapes, side effects, and assumptions.
- Reusable API or package-boundary changes update the relevant human component doc and this file if agent rules change.
- Do not update this file for package implementation changes that preserve public contracts and boundary rules; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.

## Validation Routing

Package boundary or public surface changes should include project guardrails.
Use `runLabKitTests("Suites", ...)` for the touched DTA, RHS, biosignal, image, thermal, or UI
facade, and add downstream app-family suite selectors when the app-facing
contract may be affected. Use `docs/development/testing.md` for stable build-task names,
suite selectors, and GUI/non-GUI pairings.
