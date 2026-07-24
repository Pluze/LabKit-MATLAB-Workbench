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
- Headless and hidden-GUI profiles select `Env:headless` and
  `Env:hidden-gui` respectively. `AppIsolationConformanceSpec` is tagged
  `Env:isolated-process`, but no stable Build task or CI job selects that
  environment. Current green CI is therefore not isolation evidence.
- The isolation child script stops after its first App exception. It must
  continue through all Apps and return an aggregate failure report.
- `changedFast` is exact for mapped App roles, but an unmapped, Build,
  framework, or policy path widens only to headless evidence. Its fallback
  must include every affected automated environment, rather than silently
  omitting hidden-GUI or isolated-process evidence.
- `ManualChecks` is present in a compiled plan but is always empty. Empty
  metadata must not be described as an evidence boundary.

#### High-value App audit

The audit compares legacy methods and assertions with current owner specs.
`Covered` means the observable behavior has an identifiable current proof.
`Gap` means no current proof was found. `Split` means the behavior is partly
covered but named legacy branches still require an explicit decision. A legacy
GUI workflow is not considered covered by a launch smoke test.

| App | Current high-value evidence | Parity disposition |
| --- | --- | --- |
| DIC Postprocess | strain domain, masks, overlays, source/result/presentation | Split: restore one bounded load-overlay-summary GUI workflow; retain source/export edge cases after direct parity check. |
| DIC Preprocess | masks, crop geometry, alignment, history, source/result/project/presentation | Split: restore semantic layout plus pair/alignment/crop workflow proof. |
| Chrono Overlay | pulse alignment, export interpolation, presentation | Split: restore plot/export/restore workflow proof. |
| CIC | core metrics, baseline/source and access policies, nominal current, batch recompute, schema, summary, and bounded workflow | Split: retain direct display-unit, failed-summary, and plot-request branch audit; do not replace the restored automated workflow with a manual check. |
| CSC | cycle charge, modes/errors, CSV schema, presentation | Split: audit the retained edge-cycle/export branches; restore compare-and-plot workflow proof. |
| EIS | impedance mapping, source summary, result schema, presentation | Split: restore file-load/layout proof. |
| VT Resistance | scientific calculation including batch recompute, result schema, presentation | Split: restore layout/export/restore and redraw lifecycle proof. |
| Gait Analysis | segmentation, timing roles, project migration, CSV result, presentation | Split: preserve producer-reader compatibility, rejection branches, and one navigation/export/restore workflow proof. |
| Batch Crop | core/rotated crop geometry, padded-edge policy, physical size export, manifest and overwrite policy | Split: restore duplicate task handling, preview viewport/ROI lifecycle, and workflow export evidence. |
| Curvature | circle/length science, migration, result schema, source/presentation | Split: restore invalid-curve and task-fingerprint branches plus fit-and-export workflow proof. |
| FLIR Thermal | extrema, ROI measurement, project/result/source/presentation | Split: restore raw fallback, correction/default warnings, shared range bounds, and display/export workflow proof. |
| Focus Stack | fusion, registration, project/result/source/presentation | Split: restore invalid-input and file-panel branches plus load/run workflow proof. |
| Image Enhance | basic enhancement, white balance, source/result/presentation | Gap: white-ROI, subject-preserving enhancement, tool availability, preview scaling, and workflow export evidence. |
| Image Match | white-balance and tone matching, source/result/project/presentation | Split: restore protected/Lab/histogram modes, reference separation, and workflow export proof. |
| Video Marker | editable skeleton lifecycle, coarse/subpixel deterministic tracking, prediction cache, annotation migration, project/result/source/presentation | Split: restore legacy project import, annotation/export provenance, declared Toolbox parity, and marking/prediction/export workflow. |
| Figure Studio | style, overlay order, source limits, project/presentation | Gap: composite FIG import/export, canvas/title/log-axis edge cases, source handoff, and interactive preview/export workflows. |
| Nerve Response Analysis | train detection, roles, CAP metrics, migration, source/result/presentation | Split: restore legacy session-input branch and analysis workflow proof. |
| Response Review Stats | CSV parsing, aligned metrics, migration, result/presentation | Split: restore metrics/export workflow proof. |
| RHS Preview | role assignment, timing, migration, result/source/presentation | Split: restore filter discovery and preview workflow proof. |
| T-test Wizard | input table, Welch/pooled/paired/error statistics, result schema | Gap: project migration, UI selection semantics, and compare/plot/export workflow. |
| ECG Print | input controls, signal products, migration, result/presentation | Split: restore full load/analyze/plot workflow and standalone export boundary. |

Repository guardrails are a separate parity inventory: version, dependency,
documentation, release, package-boundary, sensitive-data, and launcher rules
were deleted with no executable successor found. Each old guardrail must be
classified as retained elsewhere, rewritten as public-behavior evidence, or
explicitly retired with rationale; restoring private implementation-text scans
is not acceptable.

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

1. **Framework closure.** Add an isolated profile to Build and CI; make
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
machine-readable declaration lives in `tests/runner/labkitToolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history when project policy requires them.
