# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; exact validation commands belong in
`docs/development/maintain-and-release/testing.md`; completed work belongs in
component history.

## Active debt

Last audited: 2026-07-23.

```text
toolbox-product-debt: none
architecture-migration-debt: test-framework-parity-closure
```

### Test framework parity closure

Owner: `tests/`.

Baseline: legacy test tree at `0d882669`; catalog cutover at `9faa9f06`.

#### Observable effect

The catalog cutover correctly removed legacy selector and wrapper mechanics,
but it did not establish that every high-value legacy behavior has current
evidence. A green catalog proves its selected contracts, not historical
behavioral parity. This debt closes that proof gap without restoring stage
folders, selector compatibility, generic test helpers, or one-App wrapper
classes.

#### Verified framework findings

- `tests/cases`, `tests/runner`, and `tests/shared` were replaced by
  owner-first specs, parameterized App conformance, `labkittest`, and the
  narrow `+testfixtures` package. The cutover deleted 28,840 test lines and
  added 5,524; most deletion is test code rather than product code.
- Build and CI now select `Env:path-isolated` on Linux, macOS, and Windows.
  Its catalog-selected aggregate test resets paths before every public App,
  then returns a complete failure report. This retains the App boundary without
  requiring a second concurrent named-user license checkout.
- `changedFast` now widens unmapped, Build, framework, and policy paths to
  every automated environment: headless, hidden-GUI, and path-isolated.
- `AppSmokeConformanceSpec` now verifies every compiled layout target that
  must materialize as exactly one native semantic component. Interaction
  declarations remain view targets but correctly share their owning axes; they
  are not false component IDs. This restores the common structural assertion
  formerly duplicated across the App GUI layout wrappers.
- Every production `apps/**/*.m` and `+labkit/**/*.m` source now has an
  explicit `locate` result. The guardrail includes thin public launchers, which
  select the same definition, hidden-GUI, and path-isolated closure as their
  App package. The `labkit.contract` facade has direct requirement, version,
  incompatibility, and assertion evidence under `framework/contract`.
- `ManualChecks` passed its bounded trial: a mapped `buildLayout` path emits
  an owner-derived instruction through `explain`, `plan.json`, and `run`, while
  source/result/scientific paths remain empty and manual work never passes an
  automated plan.

#### High-value App audit

The audit compares legacy methods and assertions with current owner specs.
`Covered` means the observable behavior has an identifiable current proof.
`Gap` means no current proof was found. `Split` means the behavior is partly
covered but named legacy branches still require an explicit decision. A legacy
GUI workflow is not considered covered by a launch smoke test.

| App | Current high-value evidence | Parity disposition |
| --- | --- | --- |
| DIC Postprocess | strain domain, finite ROI and edge trim, overlay generation, source/result/presentation, bounded load/generate/display/export/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| DIC Preprocess | masks, crop geometry, toolbox-free alignment, history, source/result/project/presentation, bounded pair/alignment/crop/export/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| Chrono Overlay | definition/version metadata, project migration, pulse alignment, export interpolation, presentation, generic semantic layout, bounded load/plot/export/restore workflow | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| CIC | core metrics, baseline/source and access policies, nominal current, batch recompute, result schema, success/failed summary, display-unit fallback, stable plot requests, generic semantic layout, bounded workflow | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| CSC | full/cathodic/anodic charge branches, zero-crossing subdivision, invalid statuses, all-cycle and voltage/current CSV export, edge-cycle filtering, presentation, generic semantic layout, bounded compare-and-plot workflow | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| EIS | impedance mapping, source summary, result schema, presentation, generic semantic layout, bounded load/plot/export/restore workflow | Covered: direct source/result/plot specifications plus the hidden-GUI workflow replace the legacy export/layout wrappers. |
| VT Resistance | steady/center-window and raw-voltage policies, batch recompute, result schema/failed rows/CSV, presentation, generic semantic layout, bounded load/recompute/plot/export/restore workflow | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| Gait Analysis | Video Marker producer-reader compatibility, segmentation/timing roles, project migration, CSV result, presentation, bounded navigation/export/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| Batch Crop | core/rotated crop geometry, padded-edge policy, duplicate tasks/outputs, preview viewport preservation, physical size export, manifest and overwrite policy, generic semantic layout | Covered: direct geometry, task, result, and preview specifications replace legacy automated behavior; native ROI pointer feel remains an explicit ManualCheck. |
| Curvature | circle/length science, invalid-curve branches, fit/length task fingerprints, source migration, result schema, source/presentation, bounded trace/fit/export/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| FLIR Thermal | raw fallback, correction/default warning, extrema, ROI measurement, project/result/source/presentation, shared display range, bounded radiometric display/reading/export/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| Focus Stack | fusion, registration, project/result/source/presentation, empty-source failure, generic semantic layout, bounded load/fuse/export/restore workflow | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| Image Enhance | basic enhancement, white balance, white-ROI calibration, subject-preserving enhancement, ROI availability/defaults, preview scaling, per-image export manifest, source/result/presentation, generic semantic layout | Covered: direct capability specs now replace the legacy behavioral and layout tests without a wrapper class. |
| Image Match | white-balance, tone, protected-tone, Lab-style and histogram matching; reference separation; source/result/project/presentation; bounded reference-match/export/restore workflow; generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| Video Marker | editable skeleton lifecycle, coarse/subpixel deterministic tracking, prediction cache, legacy project and annotation migration, marker/coordinate provenance, bounded marking/prediction/calibration/export/restore workflow, project/result/source/presentation | Covered: direct capability and hidden-GUI workflow specs replace the legacy wrappers. The optional Vision Toolbox comparator is explicitly retired: production has no Toolbox dependency, and deterministic synthetic tracking behavior is the retained contract. |
| Figure Studio | style, overlay order, source limits/geometry, composite FIG import/export, canvas/title/log-axis edge cases, version migrations, axes-source handoff, bounded FIG preview/export workflow, project/presentation, generic semantic layout | Covered: direct capability and bounded GUI specs replace the legacy high-value behavior without restoring its wrappers. |
| Nerve Response Analysis | train detection, roles, CAP metrics, migration, source/result/presentation, synthetic filter-record/protocol session, bounded analysis/export/reset/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| Response Review Stats | CSV parsing, aligned metrics, migration, result/presentation, bounded load/preview/export/reset/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| RHS Preview | role assignment, timing, migration, result/source/presentation, synthetic recording/filter discovery, bounded preview/ROI/export/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |
| T-test Wizard | input table, layered labels, Welch/pooled/paired/directional/error statistics, project migration, CSV result schema, generic semantic layout | Covered: direct source, run, persistence, result, and structural specs replace the legacy core/layout wrappers. |
| ECG Print | input controls, signal products, migration, result/presentation, bounded load/analyze/four-plot/export/restore workflow, generic semantic layout | Covered: direct capability and hidden-GUI workflow specs replace the legacy behavioral and layout wrappers. |

Repository guardrails are now classified as follows. Sensitive-data hygiene is
retained as a platform-independent tracked-text contract (user/drive paths and
sample timestamps). App/package ownership and launcher conformance are retained
through `TestCatalogSpec`, public-App source routing, definition conformance,
and path-isolated evidence. Public help and rendered documentation remain
validated by the dedicated docs build/check tasks. Release/version, dependency,
magic-number, rectangle-geometry, and Code Analyzer implementation scans are
explicitly retired: their old private-text heuristics do not prove a public
contract and conflict with the current ownership/metadata model. Their durable
rules live in `AGENTS.md`, version metadata, public help, and release workflow.

#### ManualChecks trial

`ManualChecks` can carry a useful responsibility handoff, but cannot be a
passing substitute for automated evidence. Retain the field only if this
checkpoint proves all of the following:

1. a mapped layout/definition source adds a stable, owner-derived manual check
   with an explicit non-automatable boundary;
2. `explain`, `plan.json`, and `run` expose it without altering automatic pass
   or fail status;
3. catalog self-tests prove that lower-level scientific, source, result, and
   presentation changes do not acquire generic manual noise; and
4. the wording names a concrete action, not a generic instruction to "test
   manually".

Manual checks cover only native dialogs, pointer feel, visual design,
real-data suitability, and scientific interpretation. They never replace a
legacy automated GUI, state, calculation, export, or migration proof. If this
trial cannot meet those conditions with a small path-derived implementation,
remove `ManualChecks` from the plan/artifacts instead of retaining empty
architecture.

#### Execution plan

1. **Framework closure.** Add a path-isolated profile to Build and CI; make
   isolation aggregate every App failure; make changed fallback include the
   required environments; add the source-route/exemption guardrail; trial the
   bounded ManualChecks model above.
2. **Scientific and state closure.** Restore CIC first, then Batch Crop,
   Video Marker, Figure Studio, Image Enhance, T-test Wizard, and each
   `Split` branch as small capability-owned specs. One legacy method can map
   to several direct contracts; do not recreate its old class shell.
3. **GUI closure.** Add structural/wiring proofs and one bounded workflow only
   where headless owner evidence cannot prove the behavior. Keep native
   dialogs, pointer feel, visual review, real data, and interpretation as
   manual boundaries.
4. **System closure.** Rebuild only high-signal repository guardrails using
   public contracts or official metadata, then record every intentional
   retirement in this table or its successor audit.

#### Acceptance and removal

The debt remains active until:

- every row above is `Covered` or has an explicit, reviewed retirement;
- all retained isolation, GUI, scientific, state, migration, export, and
  system evidence is selected by the appropriate mapped change and stable CI
  profile;
- `ManualChecks` either meets its trial conditions or is removed completely;
- focused specs, `changedFast`, and the required cross-platform CI profiles
  pass for the final commit; and
- no legacy runner, selector, folder, or wrapper compatibility is restored.

## Intentional compatibility

Read-only saved-data compatibility is not automatically migration debt. Retain
it when current user files need it and the current writer emits only the
current format:

- Video Marker imports its declared legacy project variable and writes the
  current `labkitProject` envelope.
- Current App project specs migrate supported older payload versions through
  one version-aware `Migrate` entry.
- `labkit.dta` retains documented legacy field aliases beside canonical,
  unit-explicit fields until a future major-version decision.

Do not use a saved-data promise to justify old source layouts, launch
factories, migration callback collections, or undocumented UI nodes.

## Maintaining the ledger

Open an entry only for a concrete current problem with an owner, observable
effect, focused test, completion criteria, and removal condition. Do not treat
file length, helper count, or a possible future abstraction as migration debt.

Temporary MathWorks Toolbox use must record the exact source symbol, product,
owner, repository fallback, fallback test, idempotency evidence, numeric parity
outputs and tolerance, and the condition for deleting the Toolbox branch. Its
machine-readable declaration lives in `tests/+labkittest/toolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history when project policy requires them.
