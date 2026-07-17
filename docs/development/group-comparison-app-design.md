# Group Comparison App Design

[Development index](README.md) |
[Scientific CSV interchange](scientific-csv-interchange.md) |
[App development](app-development.md) |
[Architecture](architecture.md) | [Figure Studio](../apps/labkit-core/figure-studio/README.md)

## Status And Purpose

This is the working design contract for a proposed LabKit Group Comparison
App. It guides implementation; it does not document a currently released App
or promise that the described command already exists.

The proposed product turns small experimental datasets into reproducible
group summaries, t-test results, plot previews, and portable CSV outputs. It
supports manual entry and a deliberately small set of recognizable CSV input
shapes. MATLAB project files preserve workbench state. The measurement-wide
form in [Scientific CSV interchange](scientific-csv-interchange.md) is the
preferred portable boundary. Its secondary long form is also accepted. Neither
is a required internal App representation.

The recommended permanent product identity is:

| Field | Proposed value |
| --- | --- |
| Display name | Group Comparison |
| Command | `labkit_GroupComparison_app` |
| App ID | `group_comparison` |
| Family | Statistics |
| Folder | `apps/statistics/group_comparison` |

The broader identity leaves room for later nonparametric comparisons without
claiming that the first release supports ANOVA, mixed models, or arbitrary
statistical procedures. Version 1 is a t-test workbench.

## Product Decisions

The App may normalize data into one App-owned observation table rather than a
particular spreadsheet layout. That internal table may be stricter and richer
than the shared interchange foundation. Legacy scripts and laboratory
spreadsheets are evidence for adapters, not input contracts to reproduce
literally.

The first implementation must make these decisions explicit:

- whether an analysis is descriptive, one-sample, independent, or paired;
- which rows are included;
- which dataset and metric each observation belongs to;
- group display order and comparison order;
- the reference group or selected comparison pairs;
- the t-test method, alternative hypothesis, alpha, and multiplicity policy;
- the plot summary, error display, raw-point display, and p-value annotation;
- which CSV files are authoritative data, configuration, and results.

It must not infer pairing from row position, silently remove invalid
observations, overwrite an imported source, or treat a project MAT file as the
only usable copy of scientific data.

## Workflow

The normal workflow is:

1. Create an empty observation table; import one recognized file, a same-shape
   file batch, or a repeated-block workbook; or paste tab-delimited rows.
2. Validate and normalize the data into the App-owned observation model.
3. Choose the analysis mode, dataset, metric or metrics, group order, and
   comparison plan.
4. Choose the statistical and multiplicity settings.
5. Run **Analyze & Preview** to create an immutable analysis task, result
   tables, and a plot model.
6. Review included and excluded counts, warnings, descriptive summaries, and
   comparison results.
7. Export the shared interchange observations, the richer App observations,
   or a complete portable analysis package.
8. Open the plot in a standalone MATLAB figure and use the standard Figure
   Studio handoff for final presentation styling.

Data or statistical-option changes make the last analysis stale. Plot-only
changes may redraw an existing valid result without recomputing statistics.

## App-Local Normalized Observation Table

This section proposes one possible strict internal and package representation
for the Group Comparison App. It is not the shared LabKit CSV interchange
contract, and implementation may revise it without changing the common
wide/long foundation. At the App boundary:

- `SampleID` from the shared format maps to the internal `ReplicateID`;
- wide metric columns map to internal `Metric`, `Value`, and `Unit` fields;
- `RepeatID` requires an explicit aggregation decision before a basic t-test;
- the App may generate internal `ObservationID` and schema fields;
- export must always offer the simpler shared observation table in addition to
  any richer App-specific analysis package.

### Schema Identity

The canonical file is self-identifying. Every row carries this exact schema
value:

```text
labkit.group_comparison.observations.v1
```

The repeated `Schema` value is intentional. It allows a renamed or detached
CSV to be recognized without relying on its filename or a sidecar file. A
canonical writer always emits the columns in the documented order.

Breaking column or meaning changes require a new schema identifier. A future
reader may support older identifiers through an explicit read-only importer,
but it must never reinterpret an unknown schema as the current version.

### File-Level Rules

A canonical observation CSV has:

- UTF-8 encoding; a UTF-8 byte-order mark may be accepted but is not required;
- comma delimiters and one header row;
- `.` as the decimal separator and no thousands separators;
- ordinary CSV quoting for text containing commas, quotes, or line breaks;
- no preamble, comment rows, merged headers, formulas, subtotal rows, mean
  rows, or standard-deviation rows;
- one physical row per observed value;
- canonical Boolean output as lowercase `true` or `false`;
- empty cells for optional text, never placeholder text such as `N/A`;
- finite numeric `Value` cells; `NaN`, `Inf`, and `-Inf` are not canonical
  observations.

Fully blank trailing rows may be ignored during import and are removed on
canonical export. A partially populated row is a validation error.

### Columns

The canonical column order is:

```text
Schema,Dataset,ObservationID,ReplicateID,Metric,Group,Value,Unit,PairID,Include,Note
```

| Column | Type | Required | Meaning and validation |
| --- | --- | --- | --- |
| `Schema` | text | yes | Exact constant `labkit.group_comparison.observations.v1`. Mixed or unknown values reject the file. |
| `Dataset` | text | yes | Analysis partition. Observations from different experiments, batches, or comparison families are not pooled unless they deliberately share this value. |
| `ObservationID` | text | yes | Stable row identity, unique within the file. The App generates IDs when a convenience import omits them. |
| `ReplicateID` | text | recommended | Links different metrics measured from the same replicate within one dataset and group. It does not by itself request a paired t-test. |
| `Metric` | text | yes | Measurement name such as `threshold`, `latency`, or `ratio`. Exact trimmed text defines identity. |
| `Group` | text | conditional | Required for independent and paired group analyses. It may be blank only for an explicitly configured one-sample analysis. |
| `Value` | finite double | yes | Raw or explicitly derived observed value. Units do not appear in this cell. |
| `Unit` | text | no | Unit or scale. All included rows in the same `Dataset × Metric` must use the same nonblank unit. Blank means unspecified, not dimensionless. Use a semantic token such as `dimensionless` when that meaning is known. |
| `PairID` | text | conditional | Matching key across groups for a paired comparison. Blank for independent or one-sample data. |
| `Include` | Boolean | yes | Whether this observation participates in analysis. Canonical output uses `true` or `false`. |
| `Note` | text | no | Human-readable reason, context, or exclusion note. It does not drive calculation. |

Headers are matched case-insensitively after trimming surrounding whitespace.
Two headers that become equal after normalization are an error. Canonical
export always uses the exact capitalization above.

Dataset, metric, group, and ID values are trimmed but otherwise preserve case.
The reader must not lowercase, spell-correct, or merge labels automatically.
It may warn about labels that differ only by case or surrounding punctuation.

### Identity Semantics

The IDs protect different relationships:

- `ObservationID` identifies one CSV row and is always unique.
- `ReplicateID` associates multiple metrics from the same replicate. For
  example, threshold, tolerance, and ratio values derived from one experimental
  run may share a replicate ID.
- `PairID` associates matched observations across comparison groups. It is
  used only when the analysis mode is paired.

A shared `ReplicateID` does not imply pairing across groups. A shared row
number, table order, or matching number of observations also does not imply
pairing.

For paired analysis, each included `Dataset × Metric × Group × PairID`
combination must contain exactly one observation. The default policy is to
require complete pairs. A future explicit **Complete pairs only** option may
discard unmatched pairs, but the result must report every discarded PairID
and may not apply that policy silently.

### Synthetic Canonical Example

```csv
Schema,Dataset,ObservationID,ReplicateID,Metric,Group,Value,Unit,PairID,Include,Note
labkit.group_comparison.observations.v1,demo_stimulation,obs001,rep01,threshold,Control,1.10,mA,,true,
labkit.group_comparison.observations.v1,demo_stimulation,obs002,rep02,threshold,Control,1.20,mA,,true,
labkit.group_comparison.observations.v1,demo_stimulation,obs003,rep01,threshold,Treatment_A,1.55,mA,,true,
labkit.group_comparison.observations.v1,demo_stimulation,obs004,rep02,threshold,Treatment_A,1.60,mA,,false,Excluded before analysis
labkit.group_comparison.observations.v1,demo_stimulation,obs005,rep01,tolerance,Control,7.40,mA,,true,
labkit.group_comparison.observations.v1,demo_stimulation,obs006,rep01,tolerance,Treatment_A,8.10,mA,,true,
```

These values and labels are synthetic. Repository fixtures and documentation
must not contain real laboratory paths, filenames, subject identifiers,
device identifiers, timestamps, or recognizable source values.

### Paired Example

Pairing is declared independently of replicate identity:

```csv
Schema,Dataset,ObservationID,ReplicateID,Metric,Group,Value,Unit,PairID,Include,Note
labkit.group_comparison.observations.v1,demo_paired,obs101,run01,response,Before,2.10,mV,pair01,true,
labkit.group_comparison.observations.v1,demo_paired,obs102,run02,response,After,2.55,mV,pair01,true,
labkit.group_comparison.observations.v1,demo_paired,obs103,run03,response,Before,1.95,mV,pair02,true,
labkit.group_comparison.observations.v1,demo_paired,obs104,run04,response,After,2.30,mV,pair02,true,
```

The comparison direction is always Group A minus Group B. The paired
difference and alternative-hypothesis wording must preserve that direction.

### Daily Experimental Recording Rules

For routine recording:

1. Start from the canonical header or an App-generated template.
2. Assign a new `Dataset` whenever observations must not be pooled with a
   previous experiment or comparison family.
3. Use stable, consistently spelled `Metric` and `Group` labels.
4. Record raw observations, not group means or error bars.
5. Put units in `Unit`, not in `Value`.
6. Give measurements from the same replicate a shared `ReplicateID`.
7. Fill `PairID` only when the experimental design genuinely matches units
   across groups.
8. Keep excluded numeric observations with `Include=false` and explain the
   reason in `Note`; do not delete them merely to obtain a preferred result.
9. Export or save a canonical CSV after manual App edits. The project MAT
   remains recovery state, not the sole scientific record.

An Excel Table is appropriate for entering this CSV shape because formulas,
filters, and autofill can assist entry, but the file exported for analysis must
contain values and the single canonical header only.

### Derived Metrics

Version 1 does not evaluate arbitrary formulas. Another script may calculate
a derived metric and emit it as another canonical observation row. The derived
row should reuse the source replicate's `ReplicateID` so that its experimental
origin remains traceable.

For example, a difference metric and a ratio metric calculated from two raw
metrics become separate `Metric` values. The App must not assume a particular
formula based on a metric name. A future derivation feature requires a
whitelisted formula model and its own saved contract; it must not use `eval`.

## Recognized Interchange And Convenience Imports

The shared measurement-wide and simple-long formats are the interoperability
floor. The richer App-local table is the lossless round-trip representation
for an App analysis package. Convenience inputs are accepted to reduce work
for laboratory scripts, then normalized immediately; their original shape is
not an authoritative analysis record.

### Minimal Long Format

Required columns:

```text
Metric,Value
```

Optional recognized columns:

```text
Dataset,ObservationID,ReplicateID,Group,Unit,PairID,Include,Note
```

`Group` is required before an independent or paired analysis can run.
Missing values are filled as follows:

| Missing column | Normalized value |
| --- | --- |
| `Dataset` | `Dataset 1` |
| `ObservationID` | Deterministic sequential IDs in source-row order |
| `ReplicateID` | blank |
| `Group` | blank |
| `Unit` | blank |
| `PairID` | blank |
| `Include` | `true` |
| `Note` | blank |

The App presents the normalized table and requires validation before analysis.

### Measurement-Wide Format

This convenience profile supports scripts that naturally produce one row per
replicate and one numeric column per metric.

Reserved columns are:

```text
Dataset,ObservationID,ReplicateID,Group,PairID,Include,Note
```

Every other selected numeric column becomes a `Metric`; each nonblank numeric
cell becomes one canonical observation. At minimum, the table must contain
`Group` and one numeric metric column. `Dataset` defaults to `Dataset 1`.

Example:

```csv
Dataset,Group,ReplicateID,Metric_A,Metric_B
Dataset 1,Control,rep01,1.10,7.40
Dataset 1,Control,rep02,1.20,7.10
Dataset 1,Treatment_A,rep01,1.55,8.10
```

Measurement-wide import does not infer units from column names. The user sets
units after import or the producing script emits canonical long format.

### Formats Not Recognized In Version 1

Version 1 rejects:

- one group per numeric column without an explicit `Group` field;
- multirow or merged headers;
- summary tables containing means, SD, SEM, or confidence intervals instead
  of observations;
- files that rely on cell color, worksheet position, blank separator blocks,
  or formulas for meaning;
- mixed long and measurement-wide layouts;
- unknown `Schema` values;
- arbitrary header aliases such as `Condition`, `Treatment`, or `Y` unless a
  later explicit mapping workflow is designed.

Rejecting ambiguous inputs is preferable to silently selecting the wrong
experimental model.

## CSV Recognition Algorithm

The reader follows this order:

1. Read one header row while preserving text.
2. Trim header whitespace and reject duplicate normalized names.
3. If `Schema` is present, require one supported nonblank value in every
   nonblank row. Dispatch only to that exact schema reader.
4. Otherwise, if `Metric` and `Value` exist, use the minimal-long reader.
5. Otherwise, if `Group` exists and at least one non-reserved column is
   consistently numeric, offer the measurement-wide reader and show the
   selected metric columns before import.
6. Otherwise reject the file and display the required templates.

The reader must not choose a convenience profile when more than one profile
matches ambiguously. Import status records the detected profile, source row
count, normalized observation count, warnings, and rejected-row count.

Filename is not part of recognition. A canonical file remains canonical after
renaming.

## Boundary Contract For Other Scripts And Apps

Another script or LabKit App should target the independent
[Scientific CSV interchange](scientific-csv-interchange.md) contract rather
than the Group Comparison package. The consumer supports these boundary
choices:

1. Write the preferred measurement-wide format, with metadata columns followed
   by numeric metric columns.
2. Write the simple-long form with at least `Metric` and `Value`.
3. Use a documented header-based adapter for an existing LabKit export.

A portable producer should:

- preserve one row per value;
- provide finite numeric values;
- use stable dataset, metric, and group labels;
- distinguish sample, repeat, and pair identity;
- write Boolean inclusion explicitly;
- avoid means, SD rows, presentation-only labels, or source-local paths.

The future App owns GUI-free import and export conversion functions. Sibling
production code exchanges files and must not call the `group_comparison`
package directly. Producer-consumer integration tests may call both sides to
prove the saved contract.

## Portable Analysis Package

The complete export folder contains no required MAT file:

```text
observations.csv
observations_interchange.csv
comparisons.csv
group_summary.csv
ttest_results.csv
analysis_warnings.csv        optional when warnings exist
analysis_manifest.labkit.json
```

`observations.csv` is the richer App-normalized data actually used by the
analysis and preserves excluded rows with their `Include` state. Package
export also offers `observations_interchange.csv`, which maps analyzed values
to the shared wide foundation for consumers that do not understand
Group Comparison's private schema.

### Comparison Configuration CSV

`comparisons.csv` uses schema:

```text
labkit.group_comparison.comparisons.v1
```

Columns:

| Column | Meaning |
| --- | --- |
| `Schema` | Exact comparison schema identifier. |
| `ComparisonID` | Stable unique comparison key. |
| `Dataset` | Dataset partition. |
| `Metric` | Metric tested. |
| `TestType` | `one_sample`, `independent`, or `paired`. |
| `GroupA` | First group; difference direction starts here. |
| `GroupB` | Second group, blank for one-sample. |
| `ReferenceValue` | Numeric reference for one-sample, blank otherwise. |
| `VarianceAssumption` | `unequal`, `equal`, or `not_applicable`. |
| `Alternative` | `two_sided`, `greater`, or `less`, interpreted for A minus B or value minus reference. |
| `Alpha` | Test alpha in `(0,1)`. |
| `AdjustmentMethod` | `none`, `bonferroni`, `holm`, or `bh_fdr`. |
| `AdjustmentFamily` | Stable key defining which p-values are adjusted together. |
| `Enabled` | Canonical Boolean. |
| `DisplayOrder` | Positive integer controlling result and bracket order. |

The App expands presets such as **Reference vs all** into explicit comparison
rows before analysis. The export does not rely on the preset name to recreate
the tested pairs.

### Group Summary CSV

`group_summary.csv` uses schema:

```text
labkit.group_comparison.group_summary.v1
```

Columns:

```text
Schema,Dataset,Metric,Group,Unit,NIncluded,NExcluded,Mean,SD,SEM,
CILower,CIUpper,Median,Min,Max,Status
```

Counts refer to the normalized observation table. Confidence-interval method
and alpha come from the associated analysis configuration.

### T-Test Results CSV

`ttest_results.csv` uses schema:

```text
labkit.group_comparison.ttest_results.v1
```

Columns:

```text
Schema,ComparisonID,Dataset,Metric,TestType,GroupA,GroupB,
ReferenceValue,Alternative,NA,NB,NPairs,MeanA,MeanB,MeanDifference,
SE,T,DF,PValue,PAdjusted,Alpha,Significant,CILower,CIUpper,
AdjustmentMethod,AdjustmentFamily,Status,Message
```

Rules:

- `MeanDifference` is always A minus B, or sample mean minus reference.
- `PValue` is the raw p-value.
- `PAdjusted` equals `PValue` when no correction is selected.
- `Significant` is evaluated against `PAdjusted` when an adjustment applies.
- `NPairs` is populated only for paired tests.
- inapplicable numeric fields are empty, not zero;
- an attempted but invalid comparison retains a row with a stable `Status`
  and explanatory `Message`;
- exported status, not blank statistics alone, determines whether a test
  succeeded.

Initial status vocabulary:

| Status | Meaning |
| --- | --- |
| `ok` | Test completed. |
| `insufficient_n` | A required sample or pair count is below two. |
| `incomplete_pairs` | Required PairIDs are unmatched under the selected policy. |
| `duplicate_pair` | More than one included value occupies a required pair cell. |
| `zero_standard_error` | The configured test has no estimable standard error. |
| `invalid_input` | A validated task invariant was violated. |

Status vocabulary is an export contract. New meanings are added deliberately
and documented rather than replacing old meanings silently.

### Warning CSV

When nonblocking warnings exist, `analysis_warnings.csv` uses:

```text
Schema,Severity,SourceRow,Dataset,ObservationID,Field,Code,Message
```

with schema:

```text
labkit.group_comparison.analysis_warnings.v1
```

Blocking validation errors prevent analysis export. A data-only canonical
export may still be allowed so the user can repair the file elsewhere.

### Manifest

The LabKit JSON manifest records:

- App identity and version;
- schema identifiers;
- input provenance without embedding local private path details in public
  fixtures;
- parameters and comparison count;
- included, excluded, and warning counts;
- output filenames, byte counts, and hashes;
- the deterministic analysis-task fingerprint.

CSV files remain independently interpretable without the manifest.

## Statistical Contract

### Analysis Modes

The interface exposes explicit modes rather than a **Use grouping** checkbox:

| Mode | Required data | Calculation |
| --- | --- | --- |
| `descriptive` | values, optional groups | summaries and plots only |
| `one_sample` | values and reference value | one-sample t-test |
| `independent` | two groups | Welch or pooled two-sample t-test |
| `paired` | two groups and PairID | paired t-test on A-minus-B differences |

### Initial Options

Version 1 targets:

- two-sided, greater, and less alternatives;
- alpha default `0.05`;
- Welch unequal-variance test as the default independent method;
- pooled equal-variance test only by explicit selection;
- `none`, Bonferroni, Holm, and Benjamini-Hochberg FDR adjustment;
- adjustment per `Dataset × Metric` by default;
- raw and adjusted p-values in every successful result;
- mean difference and confidence interval in every successful test.

One explicitly planned comparison defaults to no adjustment. Generated
families such as **Reference vs all** and **All pairwise** initially propose
Holm adjustment, but the saved explicit comparison rows are authoritative.
The App never changes adjustment after analysis without a user action.

The App does not run a normality or variance test and then silently choose a
t-test variant. Diagnostics may be displayed, but the method remains an
explicit user decision.

### Missing, Invalid, And Excluded Values

Canonical included observations are finite. An invalid included value blocks
analysis rather than disappearing through `omitnan`. Intentional exclusions
use `Include=false` and contribute to `NExcluded`.

Groups with fewer than two included observations remain visible in summaries.
Their comparisons return `insufficient_n`. Zero estimated standard error
returns `zero_standard_error`; the App does not manufacture a p-value.

### Base MATLAB Implementation

Production calculations use base MATLAB and repository code. Student-t
probabilities and critical values can be implemented with beta functions. The
App does not require Statistics and Machine Learning Toolbox and does not
depend on the biosignal facade merely because that facade currently contains
a Welch comparison.

Tests use synthetic golden values for one-sample, pooled, Welch, paired,
one-sided, confidence-interval, and adjustment cases. Repeating the same task
must reproduce all App-consumed numerical results and output ordering.

## Plot Contract

The App owns scientific plot meaning:

- dataset, metric, group, and comparison selection;
- display order and labels;
- raw points and replicate/pair relationships;
- summary and error definition;
- significance brackets and p-value source;
- axis labels and units.

Figure Studio owns presentation refinement such as font, line weight, grid,
canvas, and final raster/vector export.

Initial plot presets are:

- raw points plus mean and 95% confidence interval;
- raw points plus mean and SD;
- mean bars plus SD, SEM, or confidence interval for legacy compatibility;
- paired points with connecting lines;
- grouped metrics for selected metrics and groups.

Jitter is deterministic from stable observation identity. Axis limits reserve
space for errors and ordered significance brackets. Annotation may show exact
p, stars, both, or neither; the plot model records whether raw or adjusted p
drives the annotation.

The renderer uses Figure Studio-supported primitive graphics:

- `scatter` for observations;
- `patch` for bars or boxes;
- `line` for summaries, errors, pair connections, and brackets;
- `text` for labels and annotations.

It should not rely on unsupported compound chart objects for content that must
survive the standard popout and Figure Studio handoff.

## Workbench Design

Control tabs:

| Tab | Responsibilities |
| --- | --- |
| Data | New/import/export data, template download, add/duplicate/delete rows, paste, validation status. |
| Comparisons | Analysis mode, dataset and metric selection, group order, reference and selected pairs, PairID status. |
| Test | Method, alternative, alpha, correction, adjustment family, Analyze & Preview. |
| Plot | Preset, error type, raw points, annotations, labels, selected metrics. |
| Results | Compact group and test summaries, exclusions, warnings, stale state. |
| Export | Output folder, data-only export, complete analysis package, standalone figure. |
| Log | Import, validation, analysis, and export events. |

The primary workspace contains an editable observation `resultTable` and a
registered preview area. Editing uses semantic table events. Numeric values are
sanitized before entering durable state.

The normal standalone-figure path uses the framework popout interaction and
its Figure Studio handoff. The App does not call a sibling App package.

## Durable Project And Transient Session

Proposed durable project fields:

```text
project.inputs.sources
project.inputs.observations
project.parameters.analysis
project.parameters.comparisons
project.parameters.groupOrder
project.parameters.plot
project.annotations
project.results.lastAnalysisFingerprint
project.results.lastDataExport
project.results.lastPackageExport
project.extensions
```

The normalized observation table is durable because manually entered and
edited data must survive project recovery. Imported source records preserve
provenance; they are not overwritten. A dirty-data fingerprint records whether
the durable table changed after the last canonical CSV export.

Proposed transient session fields:

```text
session.workflow.statusMessage
session.workflow.lastAction
session.workflow.outputFolder
session.view.selectedDataset
session.view.selectedMetric
session.cache.validation
session.cache.analysisTask
session.cache.summary
session.cache.comparisons
session.cache.plotModel
```

Result caches are rebuilt from validated durable observations and parameters.
Graphics handles, tables duplicated only for rendering, and runtime resources
do not enter project state.

## Proposed Source Shape

```text
apps/statistics/group_comparison/
├── labkit_GroupComparison_app.m
└── +group_comparison/
    ├── definition.m
    ├── definitionActions.m
    ├── projectSpec.m
    ├── createSession.m
    ├── +sourceFiles/
    │   ├── readObservationCsv.m
    │   ├── readInterchangeCsv.m
    │   ├── readFileBatch.m
    │   ├── applyBlockRecipe.m
    │   ├── buildFilenameMapping.m
    │   ├── importProfiles.m
    │   ├── normalizeObservationTable.m
    │   ├── validateObservationTable.m
    │   └── writeInterchangeCsv.m
    ├── +analysisRun/
    │   ├── buildAnalysisTask.m
    │   ├── summarizeGroups.m
    │   ├── computeComparisons.m
    │   └── adjustPValues.m
    ├── +resultFiles/
    │   ├── buildResultTables.m
    │   └── writeAnalysisPackage.m
    ├── +userInterface/
    │   ├── buildWorkbenchLayout.m
    │   ├── presentWorkbench.m
    │   └── drawComparisonPreview.m
    └── +debug/
        └── writeSamplePack.m
```

No new `+labkit` public facade is planned. App-specific statistics, CSV
schemas, plots, status wording, and exports remain App-owned.

## Build Plan

### Milestone 1: Data Contract

- implement shared measurement-wide and simple-long boundary import and export;
- implement App-local observation parsing, validation, and writing;
- implement minimal-long and measurement-wide normalization;
- implement same-shape batch mapping and reusable repeated-block recipes;
- implement editable, mixed-rule filename mapping for file-level metadata;
- create synthetic good, boundary, and malformed fixtures;
- implement editable-table round trips and dirty/export fingerprints;
- publish template generation from the schema owner rather than tracking a
  manually edited example CSV.

### Milestone 2: Small Complete Analysis

- implement one metric, independent Welch, two-sided tests;
- implement reference-vs-all and selected-pair expansion;
- create summaries, raw and adjusted result columns, and status handling;
- render raw points plus mean/CI with primitive graphics;
- export observations, comparisons, summaries, results, and manifest.

### Milestone 3: Complete T-Test Surface

- add one-sample, pooled, paired, and directional tests;
- add PairID validation and complete-pair reporting;
- add multiplicity methods and adjustment-family control;
- add legacy mean-bar, paired-line, and grouped-metric plots.

### Milestone 4: Integration And Polish

- add clipboard paste and template download;
- verify popout and Figure Studio transfer;
- add documented legacy header profiles only for workflows with real demand;
- add programmatic boundary normalization/writer documentation;
- add one producer-consumer saved-contract integration test;
- complete the App manual, catalog entry, generated site, component version,
  and history record when the product exists.

## Validation Plan

Unit tests cover:

- canonical header, schema, type, order, and UTF-8 round trip;
- convenience-profile recognition and ambiguous-input rejection;
- deterministic ID generation;
- dataset, metric, group, replicate, and pair invariants;
- unit consistency and exclusion counts;
- all t-test methods, alternatives, confidence intervals, and adjustments;
- explicit failures for insufficient n, incomplete/duplicate pairs, and zero
  standard error;
- stable ordering and idempotent task fingerprints;
- exact exported columns, schema identifiers, statuses, and manifest outputs;
- plot-model bracket order and deterministic jitter.

Hidden GUI tests cover:

- manual table editing and row actions;
- canonical and convenience imports;
- stale-result behavior;
- group reorder and comparison selection;
- Analyze & Preview;
- data-only and package export;
- project save/load without graphics or transient result caches.

Manual MATLAB checks cover:

- paste and table-edit feel;
- large-label and multi-metric usability;
- bracket legibility and viewport behavior;
- paired-line readability;
- standalone figure and Figure Studio transfer;
- native file and folder dialogs.

## Acceptance Criteria

The first public release is ready only when:

- a canonical CSV can be imported, exported, reimported, and compared without
  loss of scientific fields or ordering;
- the compact wide interchange CSV can be exchanged without understanding the
  App's internal schema or repeating metric names for every value;
- a minimal producer can emit `Metric`, `Group`, and `Value` and receive a
  clear normalized preview;
- every analyzed value is traceable to one canonical observation row;
- pairing, exclusions, units, and comparison direction are explicit;
- every attempted comparison has a stable status row;
- raw and adjusted p-values cannot be confused;
- project MAT recovery never becomes the only way to recover the observations;
- the exported package is usable without LabKit;
- the visible scientific plot survives the standard Figure Studio handoff;
- no real laboratory data, filenames, paths, or identifiers enter repository
  fixtures, documentation, tests, or history.

## Related Guidance

- [Scientific CSV Interchange](scientific-csv-interchange.md)
- [App Development](app-development.md)
- [Architecture](architecture.md)
- [Testing](testing.md)
- [Documentation System](documentation.md)
- [Figure Studio](../apps/labkit-core/figure-studio/README.md)
