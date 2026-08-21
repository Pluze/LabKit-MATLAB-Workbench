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
  version, layout, optional facade requirements, and references to state
  creation, state refresh, presenter, and Start capabilities.
  It performs no IO, computation, export, handle creation, or lifecycle
  mutation.
- A static App needs only the entrypoint, definition, and
  `+workbench/buildLayout.m`. Layout controls reference concrete semantic
  callbacks directly; do not create `definitionActions.m`, `stateHandlers.m`,
  callback bags, or renderer registries.
- Create only the structured in-memory state the App actually uses. The
  runtime validates only its scalar struct boundary; App field names and
  nesting are not a framework schema and are not evidence that state can be
  saved or reopened.
- Reconstruct App-specific transient data only when source changes require it.
  Read live source paths with `labkit.app.source.paths`.
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
- Production App definitions do not declare test-data builders. Synthetic
  fixtures belong to the specification owner under `tests/` only when an
  automated behavior specification consumes them. Do not preserve fixture
  protocols, manifests, launchers, or fixture-only specifications for retired
  manual reproduction workflows. A real
  user-facing demo generator, when justified, is an explicit App workflow.

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
- Production code uses only Base MATLAB and repository code. Do not call or
  conditionally accelerate with an optional MathWorks Toolbox. If Base MATLAB
  cannot satisfy the App contract, stop at the architecture boundary defined
  by the root rules.
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

## Workbench and task continuation

- Use direct semantic callbacks, strict bindings, complete
  `labkit.app.view.Snapshot` values, and `labkit.app.CallbackContext`.
  File lists own live source and selection bindings; `RefreshState`
  rebuilds App data after source changes.
  Treat file-list values as shape-agnostic collections and normalize parallel
  source, task, path, and cache arrays at the callback boundary before aligned
  insertion.
  Do not mutate registries, restore figure callbacks, create interaction
  runtimes, or add startup timers/readiness flags.
- Interactive rectangles use managed `rectangle` or `regionSelection` specs.
  One preview axis has at most one active editor for overlapping gestures;
  combine placement and movement in one interaction instead of depending on
  focus order. Movable rectangles expose an ordinary interior/center drag
  affordance, while display-only graphics disable hit testing.
- Before narrowing a native control's dynamic limits, reconcile its bound value
  into the new finite range. Defaults and automated test inputs must also remain
  valid for the smallest supported source geometry.
- Placing or editing overlays must preserve the user's viewport unless the
  user explicitly requests fit/reset.
- File and folder dialogs outside `fileList` use `CallbackContext`. Use
  `CallbackContext.inform` for successful or neutral information and
  `CallbackContext.alert` only for a blocking problem; never present an INFO
  outcome through the error-style alert capability.
- Only an App with a real continuation workflow adds save/open controls. That
  App owns its archive format, fields, compatibility policy, source lookup,
  and current-state resume semantics. Archives store one final/current
  snapshot, not intermediate adjustments or an interaction log. Analysis Apps
  without that product need do not expose or test task-state persistence.
- Caught exceptions that allow the App to continue are reported through
  `CallbackContext` before alerting or logging recovery.

## Version, docs, and tests

- Document framework-provided default lifecycle and interaction behavior only
  in the owning framework manual and public API help. Family manuals own
  family-domain meaning; App manuals own only App-specific meaning or explicit
  deviations. Never restate an SDK default across family or App pages, and
  never copy one shared-behavior paragraph across every App page.
- Source or user-visible behavior changes update `AppVersion` and `Updated` in
  the App's `definition.m`, owned documentation, and component history before
  its task-branch PR is merge-ready.
- Test GUI wiring semantically: controls, choices, events, workflow outcomes,
  viewport behavior, and traces. Launch only the minimal App input needed by
  the owning behavior specification; test calculations and exports
  directly with minimal generated inputs.
- Use the owning app-family unit suite and the app's hidden-GUI suite. Add
  project guardrails for entrypoint, boundary, fixture, or validation-policy
  changes. Exact commands belong in
  `docs/development/maintain-and-release/testing.md`.
- Record only concrete compatibility or transitional retirement work in
  `.agents/migration_guide.md`; ordinary refactoring and file size are not debt.
