# EIS manual groups for repeated scans

```labkit-change
id: CHG-20261005-eis-manual-groups
date: 2026-10-05
type: feat
compatibility: compatible
component: labkit_EIS_app | 1.8.2 -> 1.9.0
```

## Why

Repeated scans of one sample need a visible, user-controlled grouping step before mean curves and scan variability can be compared. Reviewable membership and exact frequency pairing avoid silently treating filename guesses as sample identity or averaging unrelated rows. Sample SD describes repeat-scan spread without implying a confidence interval.

## What changed

- Added a default-off Groups page with explicit add, target selection, assign, unassign, and delete controls plus group counts and file membership tables.
- Enabling group mode offers automatic recognition of identical filename prefixes before a final `-number`; later recognition fills unassigned files while preserving manual decisions.
- Added equal-weight mean curves with horizontal and vertical sample SD bars to Nyquist, Bode, and custom views, including circular phase handling and paired valid counts.
- Added grouped CSV output with frequencies, means, SD, counts, units, and plot visibility.

## Impact

Users can compare repeated scans as groups while retaining the original individual-file view. See the [EIS manual](../../use/apps/electrochemistry/eis/README.md#manual-groups-for-repeated-scans) for grouping and statistical meaning.

## Compatibility and limits

Grouping starts disabled and does not change raw file calculations or raw CSV layout. Assignments last for the current session. Groups require identical positive unique frequency sets; no implicit interpolation or tolerance matching is applied. Single contributing scans have no estimated SD, and repeated scans do not establish independent biological or specimen replication.
