# UI explicit-contract redesign: Phase 0 evidence

Captured from `main` at `7b906cbb721d81282f40a45502c7082a85fca25f`
on 2026-07-19. This folder is the compact evidence source for later phases;
generated `site/` output and ignored profiler artifacts are not design state.

After merging the release-blocking main CI repair at `a13e91d8`, the audit was
refreshed. The inventory totals and classifications were unchanged; seven
T-Test callback source locations moved by one line after bounded collection
replaced dynamic array growth. No new public symbol or transport field was
introduced.

## Freeze

Until the replacement contract is accepted, do not add a public
`labkit.ui` symbol, an App-authored UI transport field, or a new field read
through the current definition, project, layout, presentation, interaction,
event, service, resource, result, or registry structs. A release-blocking fix
must update the audit and explain why it cannot wait for the replacement.

## Inventory

- `baseline.json` is the machine-readable source-location inventory. It covers
  35 public `labkit.ui` callables, 2,812 App-side uses, 310 framework
  shadow-contract reads across 16 categories, and all 21 public Apps.
- `capability-matrix.md` is the compact per-App view.
- `behavior-classification.md` classifies each distinct App call pattern as
  `replace` or `remove`, gives its future owner, and names its test strategy.
- The 15 version-bearing paths are six dedicated facade `version.m` files and
  nine structured history records. No prohibited version-bearing architecture
  name was found. Generated `site/` mirrors are intentionally excluded.

The audit is regenerated with:

```matlab
addpath(fullfile(pwd, "tools", "migration"))
auditLabKitUiMigration(pwd, Write=true);
```

`UiMigrationBaselineTest` compares a fresh audit with the tracked JSON and
fails if an App disappears, a required shadow-contract category is missed, a
call pattern lacks a decision, or a prohibited architecture name appears.

## Required behavior and accidental behavior

Required behavior remains owned by `labkit.ui` unless the Phase 1 RFC assigns
it to an already permitted facade:

- semantic product, project, layout, presentation, signal, interaction,
  context, resource, and result capabilities;
- FIFO actions, whole-state validation, transactional presentation and
  rollback;
- saved payload version and legacy-import behavior independent of the UI
  boundary;
- deterministic cleanup and viewport preservation;
- GUI-free presenter and scientific computation paths.

The raw structs, string joins, registry/component access, callback-arity
probing, concrete container assertions, exposed figure/debug/request values,
silent fallback, and MATLAB-handle validation are accidental implementation
behavior. They are not compatibility requirements.

Every App-side source pattern has an explicit decision in
`behavior-classification.md`. `replace` means retain the capability through the
strict contract, never through a production adapter. `remove` means the new
compiler or boundary guard rejects the access.

## Late-failure baseline

The current field constructor accepts a dropdown with `items={"A"}` and
`value="B"`. Only `uidropdown` construction rejects it, with
`MATLAB:ui:DropDown:valueNotInText`. This is accidental behavior: the
replacement constructor must reject the incompatible value before any figure
exists.

`GuiLayoutUiRuntimeV2Test/workspace_tabs_build_one_native_page_group` asserts
`rightGrid`, native tab, page-grid, row-height, column-width, parent, and
selected-tab details. Those assertions are concrete-container coupling. The
semantic page membership and selection behavior are retained; the MATLAB
container shape and registry traversal are removed from App-facing tests.

The guide's third suspected case—empty or malformed factory state reaching an
action before normalization—is not reproducible at this baseline.
`createV2State` supplies required project/session buckets and
`validateV2State` runs before layout construction or startup actions.
`GuiLayoutUiRuntimeV2Test/minimal_definition_launches_without_optional_components`
proves the normalized empty state. An action can return malformed state, but
`runtime_v2_commits_queued_events_atomically` proves it is rejected before
commit and the prior state/view are restored. The replacement must preserve or
move this rejection earlier; it must not introduce the suspected late case.

## Behavior, persistence, and result baseline

The following focused hidden-GUI run passed 21 of 21 tests in 1 minute
47 seconds on MATLAB R2025b/Windows:

- `UiLayoutTest`
- `GuiLayoutUiRuntimeV2Test`
- `GuiLayoutUiRuntimeV2ProjectTest`
- `GuiLayoutTTestWizardTest`
- `GuiLayoutCurvatureTest`
- `GuiLayoutVideoMarkerTest`

Together these cover semantic layout construction; queued actions,
presentation, rollback, resources, invalid state and references; project
round-trip/migration/recovery; validated result manifests; T-Test table/edit/
plot/export behavior; Curvature point/scale/overlay/viewport behavior; and
Video resource/recovery/current-and-legacy project behavior. All files and
values are synthetic and temporary.

The exact audit consistency test separately passed 2 of 2 tests.

## Performance baseline and thresholds

`performance-baseline.json` contains three launch samples and 25 standalone
presenter samples per launch in hidden mode:

| App | Startup median | First presenter median | Repeated presenter median | Close median |
| --- | ---: | ---: | ---: | ---: |
| T-Test Wizard | 3.2589 s | 1.1782 ms | 0.3145 ms | 0.1673 s |
| Curvature Measurement | 2.8126 s | 0.9541 ms | 0.1321 ms | 0.1419 s |
| Video Marker | 3.5291 s | 2.8938 ms | 0.2989 ms | 0.1705 s |

The cold first T-Test launch was 11.4097 seconds; the table uses medians so
one-time MATLAB UI initialization does not become an architecture target.

Valid `profileLabKitTarget` startup captures (`run_error: none`) are local
under `artifacts/profile/`:

- `migration-phase0-ttestwizard-startup.{html,json}`: 5.0149 s entrypoint
  total;
- `migration-phase0-curvaturemeasurement-startup.{html,json}`: 2.1461 s;
- `migration-phase0-videomarker-startup.{html,json}`: 2.4390 s.

The profiles identify native component creation and current layout building as
the dominant inclusive costs. They do not justify an optimization by
themselves.

On the same MATLAB release, platform, GUI mode, and representative scenario,
the accepted prototype must satisfy:

- three-run startup median no greater than `1.20 * baseline + 0.25 s`;
- first standalone presenter median no greater than the larger of twice the
  baseline and 5 ms;
- repeated standalone presenter median no greater than the larger of twice the
  baseline and 1 ms;
- no regression in the focused behavior, persistence, result, rollback, or
  cleanup tests.

These are prototype rejection thresholds, not claims about interactive visual
quality. Native dialogs, pointer feel, scientific validity, and full manual
workflows remain unverified by Phase 0.
