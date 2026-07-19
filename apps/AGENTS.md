# App Rules

Apps are first-class products. They own their scientific workflow; the
framework owns common lifecycle and interaction mechanics.

## Read before editing

Read the app source and nearby tests, `docs/apps/README.md`, and
`docs/development/app-development.md`. Read only the relevant framework or
library manual for APIs the app actually uses. App tests live under
`tests/cases/unit/apps/` and `tests/cases/gui/apps/`.

## Required app shape

- Keep `labkit_*_app.m` as a thin wrapper around
  `definition().launch(...)`.
- `definition.m` is the single product contract. It declares stable identity,
  version, requirements, layout, and references to optional project, session,
  Command, presenter, renderer, debug-sample, and Start capabilities.
  It performs no IO, computation, export, handle creation, or lifecycle
  mutation.
- A static App needs only the entrypoint, definition, and
  `+userInterface/buildWorkbenchLayout.m`. Add `definitionActions.m` only for
  real App-owned business behavior; bindings and standard lifecycle need no
  placeholder Command. Keep short callback glue local.
- Add one `projectSpec.m` only for durable App-owned state. It returns a
  `ProjectContract` owning local
  create, validate, version-aware migrate, resume, relink, and declared
  read-only legacy-import functions as needed; Runtime owns the migration loop.
- Add root `createSession.m` only to reconstruct App-specific transient data
  with the fixed `(project,context)` signature. Resolve opaque portable
  sources through `context.sourcePaths`.
- `+userInterface/buildWorkbenchLayout.m` returns a data-only semantic layout.
  Add `presentWorkbench.m` only for dynamic views; it maps state to control,
  preview, renderer, and interaction models without IO or heavy computation.
- Do not add separate `requirements.m`, `version.m`, generic `+appLifecycle`
  or `+appState` packages, per-version migration files, or a Start callback
  that only constructs default state.
- Workflow packages use capability names such as `sourceFiles`, `analysisRun`,
  `cropGeometry`, `thermalFrames`, or `resultFiles`. Do not create technical
  buckets such as `actions`, `ops`, `io`, `ui`, `view`, `export`, `helpers`,
  `utils`, `manager`, or `processor`.
- Do not add package-root lifecycle `run.m`, `+ui/runApp.m`, app-family
  `private/` workflow helpers, string dispatchers, or app-specific packages
  outside the owning app tree.

## Ownership and behavior

- Keep formulas, units, thresholds, defaults, result fields, plot labels,
  exports, failure policy, alert text, and workflow order app-local.
- Use `labkit.dta`, `rhs`, `biosignal`, `image`, and `thermal` only for their
  documented reusable contracts. Do not duplicate a facade primitive in an
  app or push app policy into the facade.
- Production code uses MATLAB, declared MathWorks products, and repository
  code only. Temporary Toolbox use requires the repository-owned fallback,
  debt declaration, idempotency test, and numeric parity test required by the
  root rules.
- Numeric UI values are finite scalars before entering state. Scientific
  constants have semantic names and nearby rationale.
- State enums and repeated user-visible choices have one app-local owner.
- File commands register selections cheaply and load only what the current
  view requires. Large batches stay lazy unless a useful first view requires
  full parsing.
- Preview work uses current/display-resolution data; original-resolution batch
  work belongs at Run or Export. Pixel-unit preview parameters scale with
  preview resolution.
- Repeatable Run/Export workflows use immutable task snapshots and
  deterministic fingerprints when stale or duplicated work is possible.

## UI and persistence

- Use Commands, strict bindings, Presentation, and RuntimeContext.
  Do not mutate registries, restore figure callbacks, create interaction
  runtimes, or add startup timers/readiness flags.
- Interactive rectangles use managed `rectangle` or `regionSelection` specs.
  Display-only rectangles disable hit testing.
- Placing or editing overlays must preserve the user's viewport unless the
  user explicitly requests fit/reset.
- File and folder dialogs outside `filePanel` and alerts use RuntimeContext.
- External files in saved projects use portable references and field-specific
  relinking. Current saves use the project envelope; compatibility importers
  are read-only.
- Caught exceptions that allow the app to continue are reported through the
  RuntimeContext before alerting or logging recovery.

## Version, docs, and tests

- Source or user-visible behavior changes update `AppVersion` and `Updated` in
  the App's `definition.m`, owned documentation, and component history before
  direct-main push or merge.
- Test GUI wiring semantically: controls, choices, events, workflow outcomes,
  viewport behavior, and traces. Test calculations and exports directly with
  synthetic inputs.
- Use the owning app-family unit suite and the app's hidden-GUI suite. Add
  project guardrails for entrypoint, boundary, fixture, or validation-policy
  changes. Exact commands belong in `docs/development/testing.md`.
- Record only concrete compatibility or transitional retirement work in
  `.agents/migration_guide.md`; ordinary refactoring and file size are not debt.
