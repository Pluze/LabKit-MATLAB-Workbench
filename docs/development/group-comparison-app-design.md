# T-Test Wizard Design

[Development index](README.md) |
[App manual](../apps/statistics/ttest-wizard/README.md) |
[App development](app-development.md) |
[Simple scientific CSV exchange](scientific-csv-interchange.md)

## Product Boundary

T-Test Wizard answers:

> Given two or more ordered numeric groups, what are the configured t-test
> results for every later group versus the first, and how should that completed
> family be visualized?

The App owns visible group selection, order, test settings, result rows, plot
meaning, export schemas, and failure wording. It does not choose the
scientifically correct test, infer independence or pairing, apply automatic
multiple-comparison correction, or replace ANOVA and repeated-measures models.

| Field | Value |
| --- | --- |
| Display name | T-Test Wizard |
| Command | `labkit_TTestWizard_app` |
| App ID | `ttest_wizard` |
| Family | Statistics |
| Version | 1.0.0 |

No new `+labkit` facade is involved. The multi-group policy stays App-local.

## Workflow

```text
Select or enter groups
  -> order groups with reference first
  -> choose one test specification
  -> run group 2..N versus group 1
  -> review result family
  -> draw bar or box comparison plot
  -> export group and result CSVs
```

The left controls are Data, Test & Plot, Export, and Log. The right workspace
has native Data and Plot pages. Data stacks the opened source table and
editable analysis table at equal height; Plot gives the figure the full
workspace. A compact freshness field stays beside the plot controls. Result
rows stay beside the test controls, removing a result-only navigation step.

## Data Boundary

The source grid accepts readable CSV, TSV, XLSX, and XLS tables. Selection is
schema-free: finite numeric cells and numeric text are copied in visible
spreadsheet order; blanks and labels are skipped with counts; nonfinite numeric
cells block the selected range.

Each capture appends one durable group:

```text
group.label
group.values
group.sourceDisplayName
group.sheet
group.cellAddresses
```

Only `label` and `values` participate in calculation identity. Source metadata
supports traceability and remains App-owned. A source can be replaced without
discarding captured groups.

The ordered group editor has `Group` and `Value` columns with one observation
per row. Repeated labels form one group, and first label appearance defines
group order. The first group is the reference. Blank rows support manual entry.
The capture dropdown contains `(new group)` plus current labels, so a source
selection can create a group or append to an existing one without an
unexplained count column.

For new groups, the App scans upward from the selected numeric cells and
combines at most two nonnumeric header levels. Looking left on the same header
row supports merged-style spreadsheet headings. Dates, numeric summaries, and
row numbers are excluded. The result is only an editable suggestion, not a
calculation identity inferred from the source.

The editor supports batch group changes and deletion of selected observation
rows. Deleting the final observation removes the empty group; clearing all
data remains a distinct action. Table selection is delivered after the
completed selection changes so pointer dragging does not trigger repeated
presentation commits.

## Statistical Contract

`runTTest` remains the two-vector primitive. `runGroupTTests` calls it once for
each later group:

```matlab
for k = 2:numel(groups)
    results(k - 1) = runTTest( ...
        groups(1).values, groups(k).values, optionsForTheseLabels);
end
```

Common rules:

- difference direction is reference minus comparison;
- result order matches group order after the reference;
- the same method, alternative, and alpha apply to the family;
- Welch uses Welch-Satterthwaite degrees of freedom;
- pooled testing uses the selected equal-variance model;
- paired testing analyzes displayed reference(k)-comparison(k) differences;
- paired length is checked independently for each later group;
- Student-t probabilities and confidence intervals use the Base MATLAB
  implementation already owned by the App;
- each comparison preserves stable failure status instead of fabricating a
  number;
- no p-value correction is applied.

The completed result family stores copies of the reference vector and each
comparison vector. Plot callbacks consume those copies and cannot recalculate
the tests.

## Result And Plot Model

Each result row includes the method, alternative, alpha, labels, sample counts,
means, SDs, reference-minus-comparison estimate and interval, standard error,
t statistic, degrees of freedom, exact p-value, status, and message.

Significance shorthand is presentation metadata:

```text
p < 0.0001 -> ****
p < 0.001  -> ***
p < 0.01   -> **
p < alpha  -> *
otherwise  -> NS
```

The plot contract follows the supplied laboratory reference figure:

- white axes and canvas;
- black box and ticks, no grid;
- explicit numeric y ticks and ordinary horizontal x-axis tick labels;
- modest default typography intended for later Figure Studio adjustment;
- either one pastel mean bar with sample-SD error bar or one colored box per
  group;
- black edge, cap, and annotation strokes;
- stacked brackets from x=1 to x=2..N;
- shorthand label centered above each bracket;
- optional deterministic raw-value overlay.

The first four colors are:

```text
#9DD39C  #F5C38A  #A9D8E8  #FFF89A
```

They cycle deterministically for additional groups. Plot limits reserve space
for every successful bracket. Failed comparisons remain visible as group bars
but do not receive a misleading significance annotation.

## Export Contract

The data CSV has `Row` followed by one uniquely named column per group. Shorter
groups are padded with blank cells.

The result CSV has one row per later group and columns for:

```text
method, alternative, alpha, reference label, comparison label,
sample counts, means and SDs, difference and interval,
SE, t, df, p, shorthand, status, message
```

CSV remains the portable boundary. The project MAT file is for recovery, not
the only recoverable copy.

## Persistence And Migration

Project schema version 2 replaces:

```text
inputs.vectorA
inputs.vectorB
```

with:

```text
inputs.groups
```

Migration from version 1 preserves vector A as group 1 and vector B as group 2,
including labels, values, and source metadata. A not-run scalar result becomes
an empty result family; an existing completed A/B result remains the one-row
family for those migrated groups.

## Validation

Unit evidence covers:

- table-cell extraction and source preservation;
- Welch, pooled, paired, and directional reference values;
- ordered first-versus-each result generation;
- result-family identity after group mutation;
- multi-column group CSV and multi-row result CSV;
- stable individual failure statuses.

Hidden GUI evidence covers:

- capture of three selections;
- ordered group state;
- two comparisons against the first group;
- equal-height source/editor tables and native Data/Plot workspace pages;
- stale-plot messaging after a manual data edit;
- boxed, grid-free rendered axes;
- group and result exports.

Manual validation remains required for:

- native dialogs;
- large and irregular workbooks;
- group-table editing feel;
- long label wrapping;
- visual bracket spacing with many groups;
- publication suitability and scientific interpretation.

Private laboratory files may be used only as local evidence. No real paths,
filenames, identifiers, timestamps, or recognizable values enter tracked
fixtures or documentation.
