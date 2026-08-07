# Statistics Apps

Statistics Apps start from explicit observations selected or entered by the
user. They keep data preparation, hypothesis testing, completed results, and
figure design as separate steps so a visual change cannot silently alter a
test.

## Choose An App

| What you want to do | App | Main result |
| --- | --- | --- |
| Select two or more groups, compare each later group with the first, and draw a mean/SD plot | [T-Test Wizard](ttest-wizard/README.md) | ordered t-test family, group CSV, result CSV, and plot |

## Table And CSV Boundary

An input file does not need a LabKit schema. T-Test Wizard first shows CSV,
TSV, XLSX, and XLS sources as spreadsheet cells, then lets the user choose the
numeric ranges that have scientific meaning. The first captured group is the
reference and every later group is tested against it.

For exchange between Apps and scripts, prefer the
[Simple Scientific CSV Exchange](../../development/data-and-designs/scientific-csv-interchange.md):
one header row, one rectangular table, readable labels, and blank cells for
missing values. This is a lowest-layer table contract, not a universal
experiment schema.

## Related Documentation

- [T-Test Wizard manual](ttest-wizard/README.md)
- [Simple Scientific CSV Exchange](../../development/data-and-designs/scientific-csv-interchange.md)
- [All Apps](../README.md)
