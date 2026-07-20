# T-Test Wizard

T-Test Wizard captures two or more numeric groups, compares every group after
the first with the first group, and draws one publication-oriented mean and
standard-deviation plot. The first group is always the reference group.

## Open T-Test Wizard

From the LabKit launcher, select **T-Test Wizard** and choose **Open**. From a
source checkout, run:

```matlab
labkit_TTestWizard_app
```

The App requires Base MATLAB and the LabKit App Framework. It does not require
Statistics and Machine Learning Toolbox.

## Workflow

The left controls use three short pages:

1. **Data** — open a table, choose where selected values go, or clear data.
2. **Test & Plot** — choose one t-test, run all comparisons, review result
   rows, and adjust plot presentation.
3. **Export** — save all group observations and result rows as separate CSVs.

The right workspace has two user-selectable pages:

- **Data** keeps the opened source table above the editable analysis table,
  each using half of the workspace.
- **Plot** gives the completed statistical figure the full workspace.

Changing data or test settings does not silently recalculate the plot. A compact
status beside the plot controls reports **OUT OF DATE** until
**Run / refresh comparisons** is used again.
The short **What will run** and **Result family** summaries stay compact so
the result table and plot controls receive most of the vertical space.

## Add Groups From A Table

The Data step accepts `.csv`, `.tsv`, `.xlsx`, and `.xls`. Workbook worksheets
can be selected from the dropdown. Headers and labels remain visible in the
source grid.

For each group:

1. select its numeric cells;
2. leave **Source selection to** at `(new group)`, or choose an existing group;
3. choose **Add selected source cells**;
4. repeat for every additional group.

Finite numeric cells and numeric text are accepted. Blank and label cells are
skipped with a visible count. `NaN` and infinities block that selection until
they are excluded or corrected. Opening another file replaces the source grid
but keeps all groups already captured.

For a new group, the App proposes a name from the nearest useful header above
the selection. It follows merged-style headings to the left and combines up to
two useful levels, such as `Treatment A - Metric Y`. Dates, row numbers, and
numeric summary cells are not used as names. The proposed label remains
editable in the analysis table.

The lower analysis table uses one row per observation:

| Column | Meaning |
| --- | --- |
| Group | Editable category label; repeated labels belong to one group |
| Value | One finite numeric observation |

Type or paste directly into either column. Blank rows are available for manual
entry without a source file. Group order follows the first appearance of each
label in this table; the first group is the reference. To change the reference,
reorder the corresponding rows and edit any cell so the new order is committed.
The interface deliberately does not expose an unexplained `N` column.

To relabel many observations at once, select their rows in the analysis table,
choose an existing group under **Change selected rows to**, and use
**Change selected rows**. Selection is committed when the completed table
selection changes, so dragging across a range does not repeatedly rebuild the
App while the pointer is still moving. Use **Delete selected rows** to remove
only the selected observations; if every observation in a group is deleted,
that empty group is removed. **Clear all data** remains the separate full-reset
action.

## Choose The Tests

One selected method is applied to every comparison:

| Choice | Calculation and use |
| --- | --- |
| Independent t-test — Welch | Independent groups without an equal-variance assumption; default |
| Independent t-test — equal variances | Pooled-variance independent test |
| Paired t-test | Row-by-row differences between the first group and each later group |

The Question dropdown offers two-sided, first greater than comparison, or
first less than comparison alternatives. Difference direction is always:

```text
first/reference group minus comparison group
```

Alpha defaults to `0.05`. No multiple-comparison correction is applied. The
App reports each requested t-test exactly as configured; whether correction,
ANOVA, a mixed model, or another method is scientifically appropriate remains
the user's responsibility.

Every group needs at least two finite observations. Paired testing additionally
requires each comparison group to have the same length as the first group.
Pairing follows displayed row order and is never inferred from a filename,
header, or equal length.

## Results

**Run / refresh comparisons** creates `N - 1` immutable result snapshots for
`N` groups.
Each row reports:

- comparison and reference labels;
- sample counts;
- group means;
- reference-minus-comparison difference;
- t statistic, degrees of freedom, and exact p-value;
- `NS`, `*`, `**`, `***`, or `****`;
- stable success or failure status.

The thresholds used for the shorthand plot labels are:

| Label | Rule |
| --- | --- |
| `NS` | `p >= alpha` |
| `*` | `p < alpha` |
| `**` | `p < 0.01` |
| `***` | `p < 0.001` |
| `****` | `p < 0.0001` |

The exact p-value remains available in the result table and CSV. Editing groups
or test settings afterward does not rewrite the completed family; rerun to
create a new family.

## Plot Style

The plot uses the copied completed-result observations, not live editor values.
Choose **Mean bars with SD** or **Box plot** without recalculating the tests.
Both styles use numeric y-axis ticks, ordinary horizontal x-axis tick labels,
and the same annotation geometry. Figure Studio can adjust typography and
label presentation after the plot is popped out.

The bar visual contract is:

- one pastel bar per group;
- bar height equal to the group mean;
- dark, capped sample-standard-deviation error bars;
- a zero-anchored y-axis for all-positive or all-negative bars, including
  after wheel or toolbar zoom;
- black boxed axes on a white background;
- Helvetica labels and no grid;
- stacked brackets from the first bar to every later successful comparison;
- significance shorthand on each bracket.

The first four colors are soft green, orange, blue, and yellow; the palette
cycles for additional groups. The box style uses the same group colors with
subtler fill, dark outlines, whiskers, and medians. When individual values are
shown, the box chart's own outlier markers are suppressed so observations are
not drawn twice. Optional controls overlay individual values, hide SD bars on
bar plots, hide brackets, and edit the title or y-axis label.

Initial limits include bars or boxes, visible individual values, error bars,
and significance brackets. **Reset plot view** recomputes that fitted viewport
without rerunning the tests or changing project data. Switching between bar
and box styles also accepts the new style's fitted limits; ordinary redraws
otherwise preserve the user's current zoom.

Use **Plot > Pop out all plots** for a standalone MATLAB figure. The popout can
be passed to
[Figure Studio](../../labkit-core/figure-studio/README.md) for further visual
styling without recalculating the tests.

## CSV Outputs

**Export group data CSV** writes one group per column and pads unequal groups
with blank cells:

```csv
Row,Reference,Treatment 1,Treatment 2
1,1.2,1.8,1.1
2,1.4,1.7,1.2
```

**Export comparison results CSV** writes one row per later group. Columns are:

```text
Test, Alternative, Alpha, Reference Group, Comparison Group,
N Reference, N Comparison, N Pairs,
Mean Reference, SD Reference, Mean Comparison, SD Comparison,
Difference Reference-Comparison, SE, T, DF, P,
CI Lower, CI Upper, Significance, Status, Message
```

The imported source is never modified or overwritten.

## Programmatic Use

Run a complete first-versus-each family without opening the GUI:

```matlab
groups = struct( ...
    "label", {"Reference", "Treatment 1", "Treatment 2"}, ...
    "values", {[1.2 1.4 1.3], [1.8 1.7 2.0], [1.1 1.2 1.4]});
options = struct( ...
    "method", "welch", ...
    "alternative", "two_sided", ...
    "alpha", 0.05);
results = ttest_wizard.testRun.runGroupTTests(groups, options);
```

[`runGroupTTests`](../../../reference/api/ttest_wizard/testRun/runGroupTTests.html)
returns one canonical
[`runTTest`](../../../reference/api/ttest_wizard/testRun/runTTest.html)
result per later group.

## Project Recovery

Project schema version 2 stores ordered groups, test settings, plot settings,
completed comparison results, and source references. Version-1 A/B projects
migrate by preserving A as the first group and B as the second group.

## Assumptions And Limitations

- Observations must share a meaningful measurement unit.
- Independent tests assume independence within and between groups.
- Paired tests use the displayed row order for every first-versus-group pair.
- The App does not infer experimental units, exclusions, independence,
  biological replication, or the correct statistical model.
- No multiple-comparison correction, ANOVA, nonparametric test, regression, or
  mixed model is performed.
- Plot shorthand does not replace the exact p-value or establish scientific
  importance.

## Related Documentation

- [Statistics Apps](../README.md)
- [T-Test Wizard design](../../../development/data-and-designs/group-comparison-app-design.md)
- [Simple Scientific CSV Exchange](../../../development/data-and-designs/scientific-csv-interchange.md)
- [Figure Studio](../../labkit-core/figure-studio/README.md)
- [App Framework](../../../framework/README.md)
