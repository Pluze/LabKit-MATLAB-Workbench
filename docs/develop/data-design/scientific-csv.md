# Design And Use Scientific CSV Exchange

```labkit-page
id: develop-scientific-csv
type: concept
audience: app-developer
summary: Decide when to use the simple CSV boundary, then import, export, and validate it without inventing a universal experiment schema.
```

Use the [Scientific CSV file contract](../../reference/schemas/scientific-csv.md) for exact table shapes and legal file content. This page explains when and how an App should use that contract.

## Status And Purpose

This page explains when LabKit Apps should use the minimum CSV exchange contract and how readers and writers should apply it. The [reference page](../../reference/schemas/scientific-csv.md) alone owns the exact file rules. Adopting those rules does not change another released App contract by itself.

The contract is intentionally a table format, not a universal scientific data model. It provides a dependable lowest layer when two Apps do not share a richer schema:

- a person can type or repair it in Excel or a text editor;
- a script can read it without LabKit;
- an App can display it without first understanding its scientific meaning;
- different experiments may use different column names and row meanings;
- consumers can fall back to explicit column or cell-range selection;
- an App may add useful columns without asking the common format for permission.

There are no required `Schema`, `Dataset`, `SampleID`, `Group`, `PairID`, `Include`, or `Note` columns. There is no required filename pattern or JSON sidecar. Repeating such fields in every row would make the lowest layer harder to write without making an unfamiliar experiment unambiguous.

## The Boundary Between Source And Exchange Data

A laboratory source does not need to comply with this contract before LabKit can open it.

Source workbooks may contain repeated blocks, dates between sections, formulas, summary rows, blank separators, inconsistent filenames, and several tables on one sheet. Existing App CSVs may mix text identifiers with numeric result columns. A compatible reader first opens these files as cell grids. It then lets the user select the cells or columns that matter.

Exchange data is the simple rectangular table saved after that selection or after an App has produced a well-defined table. This distinction allows a fast, human-friendly experimental worksheet to remain useful without forcing every downstream App to reverse-engineer its layout.

```text
Existing file -> open cell grid -> select data -> copy values -> simple CSV
```

## What This Contract Deliberately Does Not Encode

The lowest layer does not claim to determine:

- which rows are statistically independent;
- whether equal-length vectors are paired;
- whether cycles or segments are samples or repeated measurements;
- whether a numeric column is raw data, a feature, or a summary;
- which group is control;
- which hypothesis test is appropriate;
- whether a filename token is a subject, condition, channel, or date.

Those decisions require experimental context. A richer App export may record them, but an unknown CSV remains usable because the fallback is visible cell selection rather than rejection.

## Reading Unknown Files

A LabKit table reader follows a compatibility ladder:

1. Read the file without requiring known headers.
2. Display the table with spreadsheet row and column coordinates.
3. If an obvious numeric column or vector exists, offer it as a convenience.
4. Always allow the user to select or revise the exact cells.
5. Copy the confirmed values into the App's own state.
6. Offer export as a simple vector or record table.

Automatic recognition is optional assistance. It must never be the only route through the App.

The reader must not show a file-level error such as “file contains nonnumeric text” merely because some cells are labels. When a selected range contains mixed cells, report the actual selection in plain language, for example:

```text
12 cells selected: 10 numbers will be used; 1 blank and 1 label will be skipped.
```

The numeric preview is authoritative. The user can change the selection before continuing.

### Cell Selection Rules

For a numeric vector:

- a single row or single column is the clearest selection;
- disjoint cells may be accepted when their order is shown in the preview;
- finite numeric cells are copied in visible row-major order;
- blanks and text are counted and shown, not silently mistaken for zero;
- `NaN`, positive infinity, and negative infinity are rejected as observations;
- the source is never overwritten during extraction.

A paired test displays the copied A and B vectors side by side and pairs them by their displayed order. Unequal lengths block the paired test but do not block an independent test.

## Standard Export From A Two-Vector Tool

A two-vector App writes the data actually used in a compact table:

```csv
Row,Condition A,Condition B
1,1.2,1.7
2,1.4,1.8
3,1.3,2.0
```

It may omit `Row` when no row labels are useful. It pads unequal independent vectors with blanks. It writes labels chosen by the user as headers and units in those headers when known.

Statistical results belong in a separate CSV because a completed test and its input observations have different row meanings:

```csv
Test,Alternative,N A,N B,Mean A,Mean B,Difference A-B,T,DF,P
Welch independent,Two-sided,3,3,1.3,1.833333,-0.533333,-5.237,3.812,0.0077
```

The values above are synthetic. Repository examples and fixtures must not contain real laboratory filenames, paths, identifiers, timestamps, or recognizable measurements.

Result writers may add effect sizes, confidence intervals, warnings, or App-specific fields. They document those columns as that App's export contract; the common CSV layer does not standardize every statistical result.

## Manual Experimental Recording

When a simple table fits the experiment, use it directly:

- put one stable header in each column;
- put raw numeric observations in ordinary cells;
- use one vector per column or one record per row;
- use blank cells for values not recorded;
- keep mean, SD, SEM, p-values, and notes outside the raw numeric range or in a separate table;
- start a new file when that is easier than making one very wide table.

When repeated visual blocks are faster during acquisition, keep the block layout. The user can later select the relevant raw cells and export a simple table. The exchange contract must not make experimental entry slower merely to simplify one future importer.

Several same-shape CSV files are also valid. A consuming App may open them one at a time, combine them, or let the user select one vector from each. Meaning encoded in filenames can be offered as editable text, but a filename pattern is never required and never silently becomes a group or pair assignment.

## Improving Existing Exports

An existing CSV already satisfies the lowest exchange layer when it has one header row and one rectangular table that meets the file contract. Improvement does not require renaming every column or converting each value into a long-form observation table.

Document what one row represents, keep released column names stable unless a normal compatibility change justifies renaming them, and separate genuinely different tables such as raw data, summaries, test results, and logs when practical. Prefer readable headers with known units, preserve useful text and status columns, and avoid absolute local paths in portable output. Add a producer-specific adapter or companion vector table only when it removes repeated work without hiding the proposed selection or inventing scientific meaning.

Reading, selection, and writing remain App-owned until several Apps demonstrate a stable, domain-neutral implementation. This design alone does not justify a new public `+labkit` facade.

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

Manual checks use representative private laboratory files without copying their names, paths, identifiers, or values into the repository.

## Related Guidance

- [T-Test Wizard](../../apps/statistics/ttest-wizard/README.md)
- [App Development](../app-authoring/app-development.md)
- [Architecture](../app-authoring/architecture.md)
- [Testing](../../maintain/testing.md)
- [Documentation System](../../maintain/documentation.md)
