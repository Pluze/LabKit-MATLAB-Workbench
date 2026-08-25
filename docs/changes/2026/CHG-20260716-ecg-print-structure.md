# ECG Print uses one project contract

```labkit-change
id: CHG-20260716-ecg-print-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_ECGPrint_app | 1.4.2 -> 1.4.3
```

## Why

ECG Print kept product metadata in separate requirement and version functions, and split one durable schema across project creation, validation, migration, and session reconstruction files under a generic lifecycle package. Session and presentation code also read the Runtime-owned portable-reference structure directly.

### Accepted choice

Use the compact Runtime V2 App structure. The definition owns product metadata and optional capabilities, one project contract owns durable schema evolution, and one root session factory rebuilds decoded signal state. ECG-specific parsing, analysis, presentation, and result packages already express real workflow capabilities and remain App-owned.

## What changed

- Consolidated command identity, display metadata, version, requirements, layout, actions, presenter, renderer, and debug capability in `definition`.
- Concentrated project creation, validation, and the version-1 source upgrade in `projectSpec` behind one `Migrate` callback.
- Moved transient recording and analysis reconstruction to root `createSession` and reused that factory when clearing a failed decode.
- Replaced nested portable-reference reads with semantic `sourcePaths` lookup.
- Removed the generic lifecycle package and separate requirement/version files.
- Updated the App package structure guardrail so actions, presentation, project persistence, and transient sessions are optional capabilities; Apps that adopt root `projectSpec` cannot regress to split lifecycle metadata.

## Impact

Recording import, parsing controls, channel selection, filtering, peak detection, segmentation, template construction, SNR measurements, plots, exports, manifests, project reopening, and user wording are unchanged. The App version advances to 1.4.3; durable payload version remains 2.

## Compatibility and limits

Version-1 projects still move their singular source record into the canonical source collection before validation. Runtime V2 now invokes the single migration entry and owns iteration to the current payload version. Current version-2 project files require no data transformation.

### Remaining limits

Automated tests do not judge ECG morphology, peak quality, or the visual suitability of exported waveforms for a particular experiment. Remaining Runtime V2 App migrations and the stale agent guidance require separate review.
