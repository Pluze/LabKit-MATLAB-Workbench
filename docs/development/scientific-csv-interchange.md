# Simple Scientific CSV Exchange

[Development index](README.md) |
[T-Test Wizard](../apps/statistics/ttest-wizard/README.md) |
[T-Test Wizard design](group-comparison-app-design.md) |
[App development](app-development.md) | [Architecture](architecture.md)

## Status And Purpose

This page defines the minimum CSV exchange contract for LabKit Apps. It guides
new exports and gradual improvement of existing exports; adopting it does not
change another released App contract by itself.

The contract is intentionally a table format, not a universal scientific data
model. It provides a dependable lowest layer when two Apps do not share a
richer schema:

- a person can type or repair it in Excel or a text editor;
- a script can read it without LabKit;
- an App can display it without first understanding its scientific meaning;
- different experiments may use different column names and row meanings;
- consumers can fall back to explicit column or cell-range selection;
- an App may add useful columns without asking the common format for
  permission.

There are no required `Schema`, `Dataset`, `SampleID`, `Group`, `PairID`,
`Include`, or `Note` columns. There is no required filename pattern or JSON
sidecar. Repeating such fields in every row would make the lowest layer harder
to write without making an unfamiliar experiment unambiguous.

## The Boundary Between Source And Exchange Data

A laboratory source does not need to comply with this contract before LabKit
can open it.

Source workbooks may contain repeated blocks, dates between sections, formulas,
summary rows, blank separators, inconsistent filenames, and several tables on
one sheet. Existing App CSVs may mix text identifiers with numeric result
columns. A compatible reader first opens these files as cell grids. It then
lets the user select the cells or columns that matter.

Exchange data is the simple rectangular table saved after that selection or
after an App has produced a well-defined table. This distinction allows a
fast, human-friendly experimental worksheet to remain useful without forcing
every downstream App to reverse-engineer its layout.

```text
Existing file -> open cell grid -> select data -> copy values -> simple CSV
```

## Minimum File Contract

A conforming exchange CSV has:

- UTF-8 text;
- comma delimiters;
- exactly one nonempty header row;
- a unique, nonempty name for every column;
- one rectangular table and no second header or table below it;
- ordinary CSV quoting for text containing commas, quotes, or line breaks;
- `.` as the decimal separator and no thousands separators in numeric cells;
- empty cells for missing values;
- evaluated values rather than spreadsheet formulas;
- no merged cells, color-dependent meaning, preamble, or comment lines.

Text and numeric columns may coexist. A file is not invalid merely because it
contains text, blanks, status messages, or columns that a particular analysis
does not use.

Headers are user-facing labels. Writers should keep them short and stable.
When a unit is useful, the recommended spelling is:

```text
Charge [mC]
Time [s]
Resistance [ohm]
```

The bracketed unit is a readable convention, not a prerequisite for opening
the file. A generic reader preserves headers exactly and does not silently
infer scientific roles from them.

## Three Useful Table Shapes

The following shapes are examples of the same contract, not separate schemas.
Apps may use other rectangular tables when their row meaning is documented.

### Vector Table

A vector table places one numeric vector in each column. It is the preferred
exchange shape for t-tests and other small comparisons:

```csv
Condition A,Condition B
1.2,1.7
1.4,1.8
1.3,2.0
```

Independent vectors may have different lengths. Shorter columns end with blank
cells:

```csv
Condition A,Condition B
1.2,1.7
1.4,1.8
,2.0
```

For a paired analysis, values on the same visible row form a candidate pair
only after the user selects a paired test. The CSV does not force one
statistical interpretation. An optional first column may give readable row
labels:

```csv
Row,Before,After
1,2.1,2.5
2,2.0,2.4
3,2.2,2.6
```

The same file can still be analyzed as two independent vectors. `Row` is an
ordinary column, not a reserved identity system.

### Record Table

A record table places one result, sample, cycle, image, segment, or other
producer-defined record on each row. Text columns describe the row and numeric
columns contain measurements:

```csv
Source,Cycle,Charge [mC],Duration [s],Status
sample_a,1,2.4,10,ok
sample_a,2,2.5,10,ok
sample_b,1,2.9,10,ok
```

This is already a useful cross-App table. A statistics App can display it and
the user can select cells from `Charge [mC]`. It does not need a conversion to
a repeated `Metric,Value` representation first.

### Series Table

A time series or curve is also a normal table:

```csv
Time [s],Signal A [mV],Signal B [mV]
0.00,0.12,0.09
0.01,0.18,0.13
0.02,0.14,0.11
```

The exchange layer preserves it. Whether curve points are valid observations
for a t-test is a scientific decision made by the user or the consuming App,
not by the CSV reader.

## Reading Unknown Files

A LabKit table reader follows a compatibility ladder:

1. Read the file without requiring known headers.
2. Display the table with spreadsheet row and column coordinates.
3. If an obvious numeric column or vector exists, offer it as a convenience.
4. Always allow the user to select or revise the exact cells.
5. Copy the confirmed values into the App's own state.
6. Offer export as a simple vector or record table.

Automatic recognition is optional assistance. It must never be the only route
through the App.

The reader must not show a file-level error such as “file contains nonnumeric
text” merely because some cells are labels. When a selected range contains
mixed cells, report the actual selection in plain language, for example:

```text
12 cells selected: 10 numbers will be used; 1 blank and 1 label will be skipped.
```

The numeric preview is authoritative. The user can change the selection before
continuing.

### Cell Selection Rules

For a numeric vector:

- a single row or single column is the clearest selection;
- disjoint cells may be accepted when their order is shown in the preview;
- finite numeric cells are copied in visible row-major order;
- blanks and text are counted and shown, not silently mistaken for zero;
- `NaN`, positive infinity, and negative infinity are rejected as observations;
- the source is never overwritten during extraction.

A paired test displays the copied A and B vectors side by side and pairs them
by their displayed order. Unequal lengths block the paired test but do not
block an independent test.

## Standard Export From A Two-Vector Tool

A two-vector App writes the data actually used in a compact table:

```csv
Row,Condition A,Condition B
1,1.2,1.7
2,1.4,1.8
3,1.3,2.0
```

It may omit `Row` when no row labels are useful. It pads unequal independent
vectors with blanks. It writes labels chosen by the user as headers and units
in those headers when known.

Statistical results belong in a separate CSV because a completed test and its
input observations have different row meanings:

```csv
Test,Alternative,N A,N B,Mean A,Mean B,Difference A-B,T,DF,P
Welch independent,Two-sided,3,3,1.3,1.833333,-0.533333,-5.237,3.812,0.0077
```

The values above are synthetic. Repository examples and fixtures must not
contain real laboratory filenames, paths, identifiers, timestamps, or
recognizable measurements.

Result writers may add effect sizes, confidence intervals, warnings, or
App-specific fields. They document those columns as that App's export
contract; the common CSV layer does not standardize every statistical result.

## Manual Experimental Recording

When a simple table fits the experiment, use it directly:

- put one stable header in each column;
- put raw numeric observations in ordinary cells;
- use one vector per column or one record per row;
- use blank cells for values not recorded;
- keep mean, SD, SEM, p-values, and notes outside the raw numeric range or in a
  separate table;
- start a new file when that is easier than making one very wide table.

When repeated visual blocks are faster during acquisition, keep the block
layout. The user can later select the relevant raw cells and export a simple
table. The exchange contract must not make experimental entry slower merely
to simplify one future importer.

Several same-shape CSV files are also valid. A consuming App may open them one
at a time, combine them, or let the user select one vector from each. Meaning
encoded in filenames can be offered as editable text, but a filename pattern
is never required and never silently becomes a group or pair assignment.

## Existing App Exports

An existing CSV is already compatible with the lowest layer when it has one
header row and one rectangular table. Migration does not require renaming all
columns or expanding each numeric cell into a long observation row.

Use these migration rules:

1. Document what one row represents.
2. Keep released column names stable unless a normal compatibility change is
   justified.
3. Split genuinely different tables—raw data, summaries, test results, and
   logs—into separate CSVs when practical.
4. Use readable headers and include units where they are known.
5. Avoid absolute local paths in portable output. A basename or user label is
   usually enough.
6. Preserve useful text and status columns; do not delete them merely to make
   a file “numeric.”
7. Add an optional companion vector table only when it materially simplifies a
   common downstream workflow.

A generic consumer reads the table and exposes manual selection. A
producer-specific adapter is justified only when it removes repeated work and
its scientific meaning is stable. The adapter still shows its proposed
selection before use.

No public `+labkit` facade is justified by this design alone. Reading,
selection, and writing remain App-owned until several Apps demonstrate a
stable, domain-neutral implementation.

## What This Contract Deliberately Does Not Encode

The lowest layer does not claim to determine:

- which rows are statistically independent;
- whether equal-length vectors are paired;
- whether cycles or segments are samples or repeated measurements;
- whether a numeric column is raw data, a feature, or a summary;
- which group is control;
- which hypothesis test is appropriate;
- whether a filename token is a subject, condition, channel, or date.

Those decisions require experimental context. A richer App export may record
them, but an unknown CSV remains usable because the fallback is visible cell
selection rather than rejection.

## Validation Expectations

Synthetic tests for a compatible reader and writer cover:

- vector tables with equal and unequal column lengths;
- record tables containing both text and numeric columns;
- series tables;
- quoted headers and text;
- blank cells and fully blank trailing rows;
- duplicate or empty headers;
- mixed selections with a visible accepted/skipped count;
- nonfinite numeric values;
- CSV write/read round trips preserving column order and displayed values;
- extraction from two different source files;
- paired preview order and unequal-length blocking;
- source files that do not match any known App profile.

Manual checks use representative private laboratory files without copying
their names, paths, identifiers, or values into the repository.

## Related Guidance

- [T-Test Wizard Design](group-comparison-app-design.md)
- [T-Test Wizard](../apps/statistics/ttest-wizard/README.md)
- [App Development](app-development.md)
- [Architecture](architecture.md)
- [Testing](testing.md)
- [Documentation System](documentation.md)
