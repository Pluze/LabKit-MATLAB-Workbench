# Scientific CSV Interchange

[Development index](README.md) | [App development](app-development.md) |
[Architecture](architecture.md) |
[Group Comparison App design](group-comparison-app-design.md)

## Status And Intent

This page defines the proposed LabKit CSV interchange foundation for scalar
scientific measurements. It is the lowest common data layer for new Apps and a
gradual migration target for existing Apps. It does not change any released
App's export contract by itself.

The foundation must be:

- simple enough to write directly in Excel or a text editor;
- rectangular and predictable enough for scripts to recognize;
- compact enough that a row does not repeat every metric name and unit;
- less restrictive than any one App's internal data model;
- explicit about the statistical meaning of a row.

It uses an open core:

- any number of scalar metric columns;
- user-chosen metric names and optional units;
- optional reserved metadata;
- extensible `Meta:` columns;
- producer-chosen column order;
- wide and long representations with defined conversion.

Only the small set of cross-App meanings is standardized. A particular
analysis may require a field, but the file convention does not require every
producer to populate fields it does not know.

An App may keep richer validation state, provenance, parameters, or
domain-specific tables. It participates in interchange by mapping its boundary
to or from this simpler table. The Group Comparison App may use a stricter
private representation; that choice does not define the shared format.

Version 1 standardizes scalar measurements only. It does not force summaries,
hypothesis-test results, time series, curve points, images, or plotting data
into the same row model.

## Practical Recording Model

Handwritten laboratory workbooks often optimize for rapid entry:

- a date or run label starts a section;
- conditions appear as adjacent horizontal blocks;
- each block repeats the same short metric headers;
- several rows hold repeated measurements;
- formula rows below hold mean and variability.

That layout is readable and efficient during an experiment, but it is not a
rectangular CSV because dates, group labels, headers, observations, and
summaries occupy different row roles.

Conversion should preserve the convenient entry layout. It only needs to
flatten each raw-measurement block into rows of one rectangular wide table.
Formula summary rows remain summaries and are not copied into the measurement
exchange file.

For example, several adjacent blocks can become:

```csv
Dataset,Group,SampleID,Threshold [mA],Tolerance [mA],Width [mA]
demo_day,Control,s01,1.10,7.40,6.30
demo_day,Control,s02,1.20,7.10,6.10
demo_day,Treatment,s03,1.55,8.10,6.50
demo_day,Treatment,s04,1.60,8.00,6.40
```

The labels and values above are synthetic. Repository documentation, fixtures,
and tests must not contain real laboratory paths, filenames, subjects, device
IDs, timestamps, or recognizable source measurements.

## Three Producer Paths

The same wide exchange table can be produced from three common laboratory
workflows. Their import mechanics differ, but their exported data contract does
not.

### Repeated Experimental Blocks

A workbook may define one visually convenient block for one experimental
round, then repeat that block horizontally or vertically for later rounds,
dates, or conditions.

The user defines a reusable block recipe once:

- block height and width;
- cells or rows that contain dataset and group labels;
- the metric-header row;
- raw measurement rows;
- formula or summary rows to ignore;
- whether repeated raw rows are independent samples or repeats;
- horizontal and vertical spacing to the next block.

The importer detects candidate blocks, shows their boundaries, and previews
the flattened wide rows. It must tolerate an incomplete final block without
silently shifting cell meanings. A user can correct one block's mapping without
changing the source workbook.

The block recipe belongs to App project or import state, not to the exchange
CSV. This keeps the output simple and lets the same recipe be reused for future
workbooks with the same layout.

### Batches Of Same-Shape CSV Files

An experiment may also use one small CSV per sample, session, or repeated run.
When all selected files share the same headers, the importer reads them as one
batch and appends their normalized rows. If some headers differ, it groups
files by detected shape and lets the user map each subgroup; one unusual file
does not invalidate the rest of the batch.

File-level meaning is entered once in a batch map:

```csv
Source,Dataset,Group,SampleID,RepeatID,Include,Note
source_01.csv,demo_day,Control,s01,,true,
source_02.csv,demo_day,Treatment,s02,,true,
```

The source names above are synthetic. A batch map is an import aid, not the
scientific measurement table. It prevents users from copying the same
dataset, group, or sample fields into every measurement row of every source
file.

The batch workflow:

1. confirms that files have the same recognized shape;
2. displays one row per file in the batch map;
3. accepts paste, fill-down, and filename-pattern suggestions;
4. requires the user to confirm any inferred group, sample, or repeat value;
5. appends the files in a deterministic visible order;
6. reports missing, duplicated, changed-header, and unreadable files;
7. exports one self-contained normalized exchange CSV.

Filename-pattern suggestions are conveniences, never scientific truth. The
saved normalized output contains explicit metadata and remains usable after
the original files are renamed or moved.

### Metadata Encoded In Inconsistent Filenames

Information may appear in either the selected CSV filename or a source-name
column such as `File`. Filenames may change structure between experiments,
days, operators, or instruments. Filename parsing is therefore an optional
editing aid, not a required profile.

The default interface is one editable row per unique source name. The user may
type or paste destination metadata directly. Optional transformations include:

- split by a chosen delimiter;
- take text before, after, or between selected tokens;
- find and replace;
- copy and fill down;
- apply a regular expression to selected rows;
- combine parsed tokens into a new value.

Each transformation creates candidate columns that can map to:

- `Dataset`;
- `Group`;
- `SampleID`;
- `RepeatID`;
- one or more `Meta:` columns;
- ignored provenance tokens.

Parsing or editing runs once per unique source name, not once per measurement
row. This
matters when an App result contains several cycles or segments for the same
source: file-level captures remain sample metadata, while the cycle or segment
column normally becomes `RepeatID`.

The mapping screen shows:

- the original basename without its local path;
- each captured token in a separate editable column;
- the proposed destination field and an editable final value;
- unmatched names, missing tokens, and collisions;
- how many measurement rows inherit each mapping.

No captured value becomes a group, sample, or pair identity until the user
confirms the preview. A trailing number might mean sample, session, channel, or
file sequence; the importer cannot decide that from syntax alone.

A single batch may use several transformations or no pattern at all. Unmatched
filenames remain editable and do not make the source unreadable. A generic
recipe is saved only when the user believes a naming convention is stable
enough to reuse; otherwise the confirmed one-off mapping stays with the import
report.

A saved recipe stores transformations and destination mappings, not real
source names. The normalized exchange CSV stores confirmed scientific metadata
and may keep a generic provenance key, but it must not require the original
path or filename for interpretation.

### Existing App Exports

An App output that already has one row per analyzed source and one numeric
column per scalar metric is close to the wide foundation. A generic mapper
selects metric columns and assigns row identity. A named App profile can add
known unit and status rules.

Summary, series, and plotting exports do not become measurements merely
because they are CSV. They require a scientifically valid scalar-feature step
or remain in their original table role.

### Import Recipes Are Not Exchange Data

A reusable import recipe may store block coordinates, header mappings,
filename patterns, units, validity rules, and source-profile IDs. Those are
instructions for converting a source, not observations.

Recipes should be saved in the importing App's durable project or a dedicated
configuration file. Portable analysis export records the applied recipe
identity and mapping in its manifest, then includes the normalized CSV. A
downstream consumer needs only the normalized CSV, not the recipe or original
workbook.

## Primary Format: Measurement-Wide CSV

### Row Meaning

One row represents one set of scalar metrics measured for one experimental
sample or repeat. Metadata appears once in the row; each metric occupies one
numeric column. This is the preferred hand-entry and cross-App form.

There is no required `Schema` column, sidecar, preamble, or repeated metric
name. Recognition comes from the single header row.

### Reserved Metadata Columns

All reserved columns are optional at the file level. An analysis may require
some of them.

| Column | Meaning |
| --- | --- |
| `Dataset` | Partition that must not be pooled with another experiment or comparison family. Default: `Dataset 1`. |
| `Group` | Condition or group label. Required when an analysis compares groups. |
| `SampleID` | Independent experimental unit that contributes to statistical sample size. |
| `RepeatID` | Technical or repeated measurement within one `SampleID`; not an independent sample. |
| `PairID` | Explicit matching key across groups for a paired analysis. |
| `Include` | Whether the row is eligible for analysis. Default: `true`. |
| `Note` | Human-readable context or exclusion reason; never drives calculation. |

Every non-reserved column is a scalar metric column and must contain numeric or
blank cells. A valid file has at least one metric column with a numeric value.

Canonical writers place available metadata first:

```text
Dataset,Group,SampleID,RepeatID,<metric columns>,PairID,Include,Note
```

They omit metadata columns that are unused. A reader must not require empty
optional columns merely to make every file look identical.

### Metric Headers And Units

The most readable metric header is:

```text
Metric name [unit]
```

Examples:

```text
Threshold [mA]
Latency [ms]
Correlation [dimensionless]
```

Square brackets at the end of a header carry the unit. Without brackets, the
unit is unspecified. The unit is not repeated in every row.

The metric identity is the trimmed text before the final bracketed unit.
Writers must not create two columns that normalize to the same metric name.
A reader preserves header case and spelling and may warn about near-duplicate
names. It must not infer units from informal suffixes unless a documented
source-specific adapter defines that rule.

### Smallest Useful Files

Ungrouped descriptive measurements can be:

```csv
SampleID,Response [mV]
s01,2.10
s02,2.35
```

A grouped experiment can be:

```csv
Group,SampleID,Response [mV],Latency [ms]
Control,s01,2.10,18.0
Control,s02,2.35,17.5
Treatment,s03,2.80,16.0
Treatment,s04,2.65,16.5
```

The format does not require placeholder values for unused concepts.

### Optional Extra Metadata

An App-specific metadata column uses the readable prefix:

```text
Meta:<name>
```

For example, `Meta:BatchPosition` is preserved as metadata and is not treated
as a numeric metric. Generic consumers do not use `Meta:` columns in
calculations unless the user maps them explicitly.

On permissive import, an unrecognized text column may be offered as metadata,
and an unrecognized numeric column may be offered as either a metric or
metadata. The preview resolves that ambiguity. Standardized export prefixes
non-reserved metadata with `Meta:` so the next consumer does not need to
guess.

New shared semantics should not be introduced through arbitrary metadata. A
field becomes reserved only after multiple Apps need the same stable meaning.

## Secondary Format: Simple Long CSV

Long form remains useful when rows contain different metrics, when metrics are
appended incrementally, or when a statistics tool needs one value per row:

```csv
Dataset,Group,SampleID,Metric,Value,Unit
demo_day,Control,s01,Threshold,1.10,mA
demo_day,Control,s01,Tolerance,7.40,mA
```

The required long-form headers are `Metric` and `Value`. It may also contain
the same metadata columns plus `Unit`:

```text
Dataset,Group,SampleID,RepeatID,Metric,Value,Unit,PairID,Include,Note
```

Long form is a supported interchange representation, not the preferred manual
recording template. A routine wide row with five metrics should not be
expanded into five repetitive rows unless a consumer needs it.

Wide and long tables are mechanically convertible:

- wide to long: each row and populated metric column becomes one value row;
- long to wide: values sharing the same metadata keys become metric columns;
- a duplicate long value for the same metadata keys and metric blocks the
  pivot until repeat identity or aggregation is resolved.

Apps may normalize wide input to long form internally without exposing that
repetition to the user or other producers.

## File And Value Rules

Writers use:

- UTF-8 text;
- comma delimiters and one header row;
- `.` as the decimal separator and no thousands separators;
- ordinary CSV quoting for commas, quotes, and line breaks in text;
- exact reserved header spelling;
- lowercase `true` and `false` for `Include`;
- empty optional cells instead of placeholders such as `N/A`;
- evaluated values rather than spreadsheet formulas.

Readers:

- trim header whitespace and match reserved headers case-insensitively;
- reject duplicate headers after normalization;
- accept `true`/`false`, `1`/`0`, and `yes`/`no` for `Include`;
- ignore fully blank trailing rows;
- preserve label case and spelling rather than silently merging groups;
- show incomplete or invalid rows instead of silently dropping them.

An included metric cell must be a finite number. A blank metric cell means that
metric was not recorded in that row; it does not create an observation.
Nonfinite values and spreadsheet errors are invalid measurements.

A failed acquisition may remain as a row with `Include=false` and a useful
`Note`, but portable writers should normally keep processing failures in a
separate warnings or log table rather than manufacture numeric observations.

## Statistical Identity

The critical distinction is between a CSV row and an independent experimental
unit.

- `SampleID` identifies the unit that contributes to sample size.
- `RepeatID` identifies multiple measurements within that unit.
- `PairID` identifies an explicit cross-group match.

Rows sharing `Dataset`, `Group`, and `SampleID` are not automatically
independent. If their `RepeatID` differs, a basic t-test must aggregate them
using a declared rule or stop and request an appropriate repeated-measure
method. It must not count technical repeats as independent samples.

For a paired analysis, every selected metric and pair must resolve to exactly
one analysis value per group. Equal row counts, row order, similar filenames,
or a shared sample label do not establish pairing.

When `SampleID` is absent, descriptive work may continue. Before inferential
analysis, a consumer must ask what one row represents or visibly warn that
independence cannot be verified. An adapter must not invent statistical
independence silently.

## Daily Recording Guidance

For a new manual sheet:

1. Use one header row such as
   `Dataset,Group,SampleID,<metric [unit] columns>`.
2. Enter one sample or repeat per row and one metric per column.
3. Give each independent experimental unit a stable generic `SampleID`.
4. Reuse that `SampleID` and add `RepeatID` for technical repeats.
5. Add `PairID` only for a genuine matched design.
6. Start a new `Dataset` when measurements must not be pooled.
7. Keep units in metric headers, not in numeric cells.
8. Put exclusions in `Include` and `Note`, not in cell color.
9. Keep mean, SD, SEM, confidence intervals, and plots outside the raw table.
10. If a block-style workbook is faster during acquisition, keep using it and
    run an explicit block-to-wide conversion before exchange.

The conversion screen for a block-style workbook should let the user identify:

- the date or dataset cell;
- each group-label cell;
- the shared metric-header row;
- raw measurement rows;
- summary rows to ignore;
- whether raw rows are independent samples or repeats within a sample.

It then previews one rectangular wide table before saving CSV.

For a repeated-block template, the App also offers **Save import recipe** and
**Apply recipe to new file**. For a same-shape file batch, it offers a
spreadsheet-like batch map with fill-down and paste rather than a dialog for
every file.

## Recognition And Mapping

A reader follows this order:

1. Read one header row and reject duplicate normalized names.
2. If `Metric` and `Value` exist, offer the simple-long reader.
3. Otherwise, classify reserved and `Meta:` columns.
4. Treat remaining consistently numeric-or-blank columns as candidate metrics.
5. Offer unknown text columns as metadata and ambiguous numeric columns for
   explicit metric-or-metadata mapping.
6. Require at least one candidate metric and show the detected row meaning.
7. If headers, row roles, or metric columns are ambiguous, open explicit
   mapping rather than guess.

Filename is never part of recognition.

The reader must not automatically treat these as measurement-wide data:

- multiple header rows or merged block headings;
- one group per numeric column without an explicit mapping;
- tables mixing raw rows with mean, SD, or SEM rows;
- meaning encoded only by color or blank separator rows;
- arbitrary aliases such as `Condition`, `Treatment`, or `Y`;
- time-series or curve points presented as independent samples.

A saved import report records source headers, detected shape, metric and unit
mappings, row counts, exclusions, warnings, and the reader version. Portable
export contains the normalized wide or long CSV so downstream tools no longer
need the original adapter.

## Table Roles Stay Separate

| Role | Example row meaning | Direct t-test input |
| --- | --- | --- |
| Scalar measurements | one sample or repeat with one or more scalar metrics | yes, after identity validation |
| Descriptive summary | mean or SD for a group | no |
| Statistical result | one completed hypothesis test | no |
| Series point | one time, voltage, or curve point | no |
| Plot data | one visible graphics point | no |
| Processing log | one success, warning, or failure | no |

Apps should export separate files for separate roles. A statistics App may
export `observations.csv`, `group_summary.csv`, and `ttest_results.csv`; only
the observations file maps to this foundation. Summary statistics must not be
reverse-engineered into raw observations.

Another shared profile should be added only after at least two independent
producers and consumers need the same stable row semantics. The foundation
should not become a universal table with dozens of mostly empty columns.

## Compatibility With Existing LabKit Outputs

Most existing CSVs predate this convention. Compatibility depends on row
meaning, not superficial tabularity:

| Existing output | Current row meaning | Compatibility path |
| --- | --- | --- |
| CIC results | one analyzed source file with scalar metrics and status | already close to wide form; map selected metrics and explicitly assign dataset, group, sample, and validity |
| VT Resistance results | one analyzed source file with scalar metrics and status | wide mapping; exclude failed rows through a documented status rule |
| CSC all-cycles results | one curve or cycle with scalar metrics | wide mapping, plus a required decision whether cycles are samples or repeats |
| Curvature results | one image with fitted scalar metrics | concatenate if needed, map metrics and units, and assign sample/group explicitly |
| ECG Print segment analysis | one segment with signal, noise, and SNR metrics | map metrics; segments from one recording are normally repeats |
| Response Review Stats metrics | one named segment with scalar metrics | map metrics; do not assume a segment name is a group or independent sample |
| Gait step table | one step with scalar gait metrics and validity | map valid metrics; recording or subject is the sample and step is normally a repeat |
| Gait summary or DIC strain summary | one precomputed statistic | retain as summary output; never import as measurements |
| EIS or Chrono Overlay export | one curve or time-series point | extract a scientifically defined scalar feature first |
| Figure Studio plot-data export | one visible graphics point | presentation data only; never treat as authoritative measurements |

The generic wide mapper covers most scalar result tables. A named legacy
profile adds safe defaults but still shows the normalized preview. It matches
a distinctive header set, never a filename, and declares:

- what one source row means;
- eligible metric columns and unit mappings;
- status or validity columns and exact exclusion rules;
- candidate sample and repeat identities;
- required user mappings for dataset and group;
- any independence or pseudoreplication warning.

`File`, `Image`, `CurveName`, `SegmentName`, and graphics object names are
provenance candidates, not automatic group labels. Local absolute paths must
not become portable sample IDs.

## Migration Policy For Apps

Migration is additive:

1. **Document row meaning.** Keep the legacy export unchanged.
2. **Add a reader profile.** Do this only for a real producer-consumer
   workflow and test the header mapping.
3. **Add a wide companion export.** When legitimate scalar measurements
   exist, optionally write a second interchange CSV.
4. **Prefer interchange at the boundary.** Keep richer or presentation-focused
   legacy tables for their original users.
5. **Retire deliberately.** Remove an old format only through normal
   compatibility, version, documentation, and history work.

Do not append required columns to a released legacy CSV merely to claim
compliance; scripts may rely on its current headers. Prefer an additional,
clearly named export or package member.

When an App exports summaries, curves, or logs rather than scalar
measurements, migration does not mean relabeling those rows. Add an
interchange companion only at a point where a legitimate scalar experimental
measurement exists.

New scalar-producing Apps should:

- own an App-local function that builds the wide interchange table;
- document what one row and `SampleID` represent;
- expose dataset, group, unit, and repeat semantics explicitly;
- test CSV write/read round trips without GUI state;
- avoid absolute paths and source-local identifiers in portable IDs;
- export summaries, tests, series, and logs separately.

An App need not use these columns internally. Interchange tests exercise the
boundary conversion, not the private representation.

No public `+labkit` facade is justified yet. Promote a domain-neutral reader
or writer only after repeated, stable use by multiple Apps demonstrates the
contract.

## Validation Expectations

Synthetic fixtures should cover:

- minimal ungrouped wide input;
- recommended grouped multi-metric input;
- multiple metrics and blank metric cells;
- technical repeats within a sample;
- paired rows;
- exclusions and malformed numeric cells;
- `Meta:` columns;
- wide-to-long and long-to-wide conversion;
- block-style acquisition conversion with summary rows omitted;
- reusable repeated-block recipes, including an incomplete final block;
- same-header multi-file batches and their one-row-per-file batch map;
- manual and mixed-rule filename mapping, parse failures, and duplicate
  inferred sample IDs;
- summary and series tables rejected as independent measurements;
- every named legacy profile added to production.

Producer-consumer tests compare normalized content, not just whether the CSV
opens. Units, sample identity, repeat identity, inclusion, metric values, and
row counts must survive the round trip.

## Related Guidance

- [Group Comparison App Design](group-comparison-app-design.md)
- [App Development](app-development.md)
- [Architecture](architecture.md)
- [Testing](testing.md)
- [Documentation System](documentation.md)
