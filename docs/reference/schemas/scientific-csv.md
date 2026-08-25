# Scientific CSV File Contract

```labkit-page
id: reference-scientific-csv-file-contract
type: reference
audience: app-developer
summary: Define the exact text encoding, header, cell, quoting, missing-value, and table-shape rules for LabKit scientific CSV exchange.
```

[Developer guide](../../develop/data-design/scientific-csv.md)

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

Text and numeric columns may coexist. A file is not invalid merely because it contains text, blanks, status messages, or columns that a particular analysis does not use.

Headers are user-facing labels. Writers should keep them short and stable. When a unit is useful, the recommended spelling is:

```text
Charge [mC]
Time [s]
Resistance [ohm]
```

The bracketed unit is a readable convention, not a prerequisite for opening the file. A generic reader preserves headers exactly and does not silently infer scientific roles from them.

## Three Useful Table Shapes

The following shapes are examples of the same contract, not separate schemas. Apps may use other rectangular tables when their row meaning is documented.

### Vector Table

A vector table places one numeric vector in each column. It is the preferred exchange shape for t-tests and other small comparisons:

```csv
Condition A,Condition B
1.2,1.7
1.4,1.8
1.3,2.0
```

Independent vectors may have different lengths. Shorter columns end with blank cells:

```csv
Condition A,Condition B
1.2,1.7
1.4,1.8
,2.0
```

For a paired analysis, values on the same visible row form a candidate pair only after the user selects a paired test. The CSV does not force one statistical interpretation. An optional first column may give readable row labels:

```csv
Row,Before,After
1,2.1,2.5
2,2.0,2.4
3,2.2,2.6
```

The same file can still be analyzed as two independent vectors. `Row` is an ordinary column, not a reserved identity system.

### Record Table

A record table places one result, sample, cycle, image, segment, or other producer-defined record on each row. Text columns describe the row and numeric columns contain measurements:

```csv
Source,Cycle,Charge [mC],Duration [s],Status
sample_a,1,2.4,10,ok
sample_a,2,2.5,10,ok
sample_b,1,2.9,10,ok
```

This is already a useful cross-App table. A statistics App can display it and the user can select cells from `Charge [mC]`. It does not need a conversion to a repeated `Metric,Value` representation first.

### Series Table

A time series or curve is also a normal table:

```csv
Time [s],Signal A [mV],Signal B [mV]
0.00,0.12,0.09
0.01,0.18,0.13
0.02,0.14,0.11
```

The exchange layer preserves it. Whether curve points are valid observations for a t-test is a scientific decision made by the user or the consuming App, not by the CSV reader.
