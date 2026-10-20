# Cheaper snapshots and balanced App validation

```labkit-change
id: CHG-20261020-snapshot-cost
date: 2026-10-20
type: perf
compatibility: compatible
component: labkit.app | 3.6.0 -> 3.6.1
```

## Why

Building complete App snapshots repeatedly reconstructed operation names from all preceding entries. Native App validation also assigned expensive workflows unevenly between its two macOS partitions, leaving one runner idle while the other finished.

## What changed

Snapshot stores operation kinds, targets, and payloads in aligned value arrays and materializes operation records at the compiler boundary. Appends no longer reconstruct previous names. Fragment inclusion, default overlays, duplicate rejection, immutable inputs, and payload shapes retain their contracts.

The existing macOS partitions use successful JUnit durations as scheduling hints, assigning longer identities first to the lighter partition. Unknown identities receive the median hint and still execute. Hints affect scheduling only; both partitions remain required and together retain every App identity.

## Impact

All Apps use the shared snapshot implementation without changes to their presenters, calculations, outputs, or saved formats. See the [SDK contract](../../develop/framework/README.md) and [test partition reproduction and hint refresh](../../develop/testing.md).

## Compatibility and limits

Local App validation remains complete by default. Historical timings estimate load rather than guarantee elapsed time; native rendering and runner load still vary.
