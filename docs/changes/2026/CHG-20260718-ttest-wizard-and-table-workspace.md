# T-Test Wizard adds table selection and first-versus-each comparisons

```labkit-change
id: CHG-20260718-ttest-wizard-and-table-workspace
date: 2026-07-19
type: feat
compatibility: compatible
component: labkit_TTestWizard_app | new -> 1.0.0
component: labkit.ui | 7.5.1 -> 7.6.0
```

## Why

Laboratory comparison data appeared as manually maintained workbook blocks, same-shape files, and rectangular App exports containing identifiers beside numeric metrics. Schema-first mapping made unfamiliar sources harder to use. The required workflow also included several treatments compared with one control, while the first implementation boundary held only A and B.

Runtime presentation could update table values but not their spreadsheet headers or collapse unused workspace panels. An App therefore could not show an unfamiliar table faithfully while giving each wizard step the full workspace.

### Accepted choice

Display CSV, TSV, XLSX, and XLS sources as visible cell grids. Let the user append each numeric selection as an ordered durable group. The first group is the explicit reference; one chosen t-test specification is then applied to every later group versus that first group.

Keep Data, Test/Plot, and Export controls short. Put Data and Plot in user-selectable right-side workspace pages, merge result review with the test, and keep completed comparisons as immutable snapshots. Plot controls consume those snapshots and cannot recalculate the result family.

Keep CSV as a low-constraint rectangular interchange boundary. Known producers may add conveniences later, but visible cell selection remains the fallback.

## What changed

- Added the Statistics family and T-Test Wizard 1.0.0.
- Added direct visible-cell selection from CSV, TSV, XLSX, and XLS, including worksheet selection, numeric-text acceptance, mixed-cell feedback, and groups captured from different sources.
- Added an ordered `Group`/`Value` observation editor, manual paste/editing, existing-group capture choices, first-appearance reference ordering, and batch reassignment or deletion of selected observation rows.
- Added layered spreadsheet-header suggestions for new group names and coalesced completed-selection delivery so range dragging does not repeatedly refresh the App.
- Added first-versus-each Welch, pooled equal-variance, and paired t-tests with two-sided and directional alternatives.
- Added Base MATLAB Student-t probabilities and intervals, stable per-result failure statuses, and immutable result snapshots.
- Added reference-style bar and box plots with pastel groups, explicit numeric axes, standard x-axis tick labels, boxed grid-free axes, and stacked `NS/*/**/***/****` brackets.
- Added multi-column group CSV and multi-row result CSV exports.
- Added project schema version 2 migration from durable A/B vectors to two ordered groups.
- Extended Runtime presentation so result tables can update headers and hidden rows collapse.
- Coalesced rapid table-selection events before App presentation and replaced stale standalone file-context titles instead of appending duplicate suffixes.
- Preserved tick labels, limits, and graphics stacking order when plots are popped into standalone figures, keeping error bars above their bars, and added a copied-figure control for switching X-axis group labels between angled and horizontal presentation. Responsive popout margins keep enlarged ticks, axis labels, and titles inside the standalone window.
- Extended `labkit.ui.layout.workspace` to accept two or more tab pages without adding a parallel workspace-specific public constructor.

## Impact

Users can select any number of groups from an unfamiliar readable table without defining a schema or removing unrelated text. Running creates one comparison row for every group after the first. Paired testing follows displayed row order for each comparison with the first group.

The App exports ordinary CSVs instead of requiring another program to decode a project MAT file. Imported sources are not modified.

## Compatibility and limits

The App and Statistics family are additive. Version-1 T-Test Wizard projects migrate A to group 1 and B to group 2, preserving labels, values, and source metadata. An earlier completed A/B result remains a one-row result family.

`labkit.ui` remains compatible with `>=7 <8`. Existing presentation structs that omit dynamic table headers and visibility behave as before.

No multiple-comparison correction is silently introduced. This preserves the meaning of each requested t-test and makes the limitation explicit.

### Remaining limits

Version 1.0.0 does not infer experimental units, independence, pairing, exclusions, or groups from filenames. It does not apply multiple-comparison correction, ANOVA, nonparametric tests, regression, or mixed modeling. Automatic numeric-column suggestions remain a possible convenience only after real use demonstrates a stable need.
