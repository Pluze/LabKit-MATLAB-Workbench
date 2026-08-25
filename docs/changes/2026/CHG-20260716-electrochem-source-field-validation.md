# Electrochemistry source-field validation boundary

```labkit-change
id: CHG-20260716-electrochem-source-field-validation
date: 2026-07-16
type: fix
compatibility: compatible
component: labkit_ChronoOverlay_app | 1.4.5 -> 1.4.6
component: labkit_CIC_app | 1.4.5 -> 1.4.6
component: labkit_CSC_app | 1.4.5 -> 1.4.6
component: labkit_EIS_app | 1.4.5 -> 1.4.6
component: labkit_VTResistance_app | 1.4.5 -> 1.4.6
```

## Why

Runtime owns the format of a portable source record but intentionally allows a project whose `inputs` bucket has no `sources` field. Static and embedded-data Apps may not use external sources. The first electrochemistry validator reduction correctly removed record-format duplication but also stopped declaring that these five file-backed Apps require a source collection.

### Accepted choice

Keep field presence with the App schema and record shape with Runtime. This is the narrow ownership split: the App decides whether sources are required; Runtime decides what every supplied source record means.

## What changed

- Restored the `inputs.sources` presence requirement in all five electrochemistry project validators.
- Added a GUI-free unit contract that accepts each default project and rejects the same project after its App-required source collection is removed.
- Kept canonical bucket and source-record field validation out of the Apps.

## Impact

Valid projects are unchanged. A malformed electrochemistry project missing its entire source collection is rejected by the App validator before session reconstruction instead of failing later while decoded data are rebuilt.

## Compatibility and limits

No saved format changed and no migration is required. Every project created or saved by these Apps already contains `inputs.sources`.

### Remaining limits

The same distinction must be applied explicitly while reducing validators in other App families; a generic source format does not imply that every App has the same required source fields or roles.
