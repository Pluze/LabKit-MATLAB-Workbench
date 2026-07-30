# App Rules

Apps are first-class products. They own their scientific workflow; the
framework owns common lifecycle and interaction mechanics.

## Read before editing

Read the app source and nearby tests, `docs/apps/README.md`, and
`docs/development/build-apps/app-development.md`. Read only the relevant
framework or library manual for APIs the app actually uses. App tests live under
`tests/specs/apps/<family>/<app>/<capability>/`. Use `labkittest.explain` to
find the exact owner and contract; App authors never invent test paths.

## Required app shape

- Keep `labkit_*_app.m` as a thin wrapper around
  `definition().launch(...)`.
- `definition.m` is the single product contract. It declares stable identity,
  version, requirements, layout, and references to optional project, session,
  presenter, synthetic-input, and Start capabilities.
  It performs no IO, computation, export, handle creation, or lifecycle
  mutation.
- A static App needs only the entrypoint, definition, and
  `+workbench/buildLayout.m`. Layout controls reference concrete semantic
  callbacks directly; do not create `definitionActions.m`, `stateHandlers.m`,
  callback bags, or renderer registries.
- Add one `projectSpec.m` only for durable App-owned state. It returns a
  `labkit.app.project.Schema` owning local create, validate, version-aware
  migrate, resume, relink, and declared read-only legacy-import functions as
  needed; Runtime owns the migration loop.
- Add root `createSession.m` only to reconstruct App-specific transient data
  with the fixed `(project,context)` signature. Resolve opaque portable
  sources through `context.resolveSourcePaths`.
- `+workbench/buildLayout.m` returns the data-only product assembly. Add
  `+workbench/present.m` only for dynamic views; it composes feature-owned
  snapshot fragments without IO or heavy computation. Put each renderer in
  the capability package that owns the plotted meaning.
- Treat complete runtime state as an adapter value, not a domain model. Only
  `createSession`, `+workbench/present`, `OnStart`, and functions referenced
  directly by layout signals may accept it. Name it `applicationState`,
  destructure it immediately, and pass exact values into feature presenters,
  calculations, renderers, and writers.
- Direct callbacks expose `applicationState`, then the typed event value when
  present, then `callbackContext`. Keep short transactional mutation there;
  do not forward the complete state or context into a generic action layer.
- Do not add separate `requirements.m`, `version.m`, generic `+appLifecycle`
  or `+appState` packages, per-version migration files, or a Start callback
  that only constructs default state.
- Workflow packages use capability names such as `sourceFiles`, `analysisRun`,
  `cropGeometry`, `thermalFrames`, or `resultFiles`. Do not create technical
  buckets such as `actions`, `ops`, `io`, `ui`, `userInterface`, `view`,
  `export`, `helpers`, `utils`, `manager`, or `processor`.
- The package tree follows the product: input capability, edit or analysis
  capability, preview or result capability, then result files. A capability
  package may own its layout fragment, direct actions, presentation fragment,
  and renderer when those files change together.
- Do not add package-root lifecycle `run.m`, `+ui/runApp.m`, app-family
  `private/` workflow helpers, string dispatchers, or app-specific packages
  outside the owning app tree.
- `BuildSyntheticSample` creates a validated, reproducible synthetic project and
  artifacts; it never authorizes startup work or automatic project loading.
  Runtime exposes generation as an ordinary Developer Tools action; every
  launch follows the same App startup path.
  Interactive sample values are finite, representative, and valid for the
  smallest native controls that will render them.

## Ownership and behavior

- Keep formulas, units, thresholds, defaults, result fields, plot labels,
  exports, failure policy, alert text, and workflow order app-local.
- Solve new behavior inside its owning capability first. If framework support
  is necessary, prefer a natural extension to an existing focused SDK
  contract or private runtime behavior. Request a new public API only for a
  stable need shared by multiple Apps or when the existing API would otherwise
  become an ambiguous bucket.
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
  work belongs at Run or Export. Every finite preview pixel budget is an
  explicit App-owned responsiveness decision; pixel-unit preview parameters
  scale with preview resolution.
- Repeatable Run/Export workflows use immutable task snapshots and
  deterministic fingerprints when stale or duplicated work is possible.

## Workbench and persistence

- Use direct semantic callbacks, strict bindings, complete
  `labkit.app.view.Snapshot` values, and `labkit.app.CallbackContext`.
  File lists own portable source and selection bindings; `createSession`
  rebuilds transient data after source changes.
  Do not mutate registries, restore figure callbacks, create interaction
  runtimes, or add startup timers/readiness flags.
- Interactive rectangles use managed `rectangle` or `regionSelection` specs.
  One preview axis has at most one active editor for overlapping gestures;
  combine placement and movement in one interaction instead of depending on
  focus order. Movable rectangles expose an ordinary interior/center drag
  affordance, while display-only graphics disable hit testing.
- Before narrowing a native control's dynamic limits, reconcile its bound value
  into the new finite range. Defaults and synthetic projects must also remain
  valid for the smallest supported source geometry.
- Placing or editing overlays must preserve the user's viewport unless the
  user explicitly requests fit/reset.
- File and folder dialogs outside `fileList` and alerts use CallbackContext.
- External files in saved projects use portable references and field-specific
  relinking. Current saves use the project envelope; compatibility importers
  are read-only.
- Caught exceptions that allow the App to continue are reported through
  `CallbackContext` before alerting or logging recovery.

## Version, docs, and tests

- Source or user-visible behavior changes update `AppVersion` and `Updated` in
  the App's `definition.m`, owned documentation, and component history before
  the `develop` PR is merge-ready.
- Test GUI wiring semantically: controls, choices, events, workflow outcomes,
  viewport behavior, and traces. A synthetic project is validated headlessly
  and launched through the native adapter; test calculations and exports
  directly with minimal synthetic inputs.
- Use the owning app-family unit suite and the app's hidden-GUI suite. Add
  project guardrails for entrypoint, boundary, fixture, or validation-policy
  changes. Exact commands belong in
  `docs/development/maintain-and-release/testing.md`.
- Record only concrete compatibility or transitional retirement work in
  `.agents/migration_guide.md`; ordinary refactoring and file size are not debt.
