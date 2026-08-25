# Committed interactions and bounded diagnostics

```labkit-change
id: CHG-20260825-committed-interactions-and-bounded-diagnostics
date: 2026-08-25
type: fix
compatibility: compatible
component: labkit.app | 3.1.1 -> 3.2.0
component: labkit_CIC_app | 1.7.0 -> 1.7.1
component: labkit_VTResistance_app | 1.7.0 -> 1.7.1
component: labkit_DICPreprocess_app | 1.8.0 -> 1.8.1
component: labkit_DICPostprocess_app | 1.7.0 -> 1.7.1
component: labkit_BatchImageCrop_app | 1.10.0 -> 1.10.1
component: labkit_CurvatureMeasurement_app | 1.7.0 -> 1.7.1
component: labkit_VideoMarker_app | 1.8.0 -> 1.8.1
component: labkit_FLIRThermal_app | 1.7.0 -> 1.7.1
component: labkit_RHSPreview_app | 1.7.0 -> 1.7.1
supersedes: CHG-20260803-app-sdk-diagnostics-and-input-workflows
```

## Why

One DIC slider drag produced 440 semantic control changes and 3,080 DEBUG records, while repeated spinner arrows produced another 81 complete state/presentation transactions. The earlier diagnostics design treated native intermediate values as App actions, expanded each action into callback implementation breadcrumbs, rewrote the manifest at durable checkpoints, retained complete callback payloads, and bounded individual sessions without bounding accumulated session folders. The result was disproportionate disk and callback work for ordinary direct manipulation, even when an individual file remained modest.

### Accepted choice

Make direct manipulation commit-driven. Slider drag updates its native value display and commits once on pointer release. Paired-spinner changes update the same display immediately and trailing-edge coalesce across a one-second quiet period; this interval reduces the observed 81-event human repeat sequence to its three separated input bursts. An unchanged final value is a no-op. Preserve no visible busy feedback for these commits because flashing pointer, title, and control state harms the interaction; instead require App callbacks on this path to remain bounded and move unbounded or potentially long IO/calculation, export, and waiting to explicit actions. One bounded current preview or automatic refresh may run after commit; a navigation control may perform one bounded current-record or current-window preview read when that read is the interaction's core purpose.

Record semantic operations rather than callback implementation traffic. A committed action owns a root start, an App-presentation checkpoint when relevant, and one terminal result, plus real nested capabilities and App-owned milestones or failures. Remove automatic state-updated, validation-success, native-commit, and rollback-cleanup records. Keep durable root and presentation breadcrumbs, but do not rewrite the manifest for each breadcrumb. Bound the live ring and viewer by records and serialized bytes, retain bounded per-session segments, prune only older closed sessions at the journal-root limit, and summarize persistence degradation at its transition instead of emitting one warning for every later dropped record.

Replace complete-sensitive diagnostic payload retention with one enforced bounded grammar. Messages reject absolute paths and original filenames. Attributes retain controlled semantic aliases, units, reasons, finite scalar counts/indices/ordinals/durations, and bounded dimensions; paths, identities, scientific values or arrays, free text, and arbitrary nesting fail before entering memory or disk. Exceptions retain a bounded identifier, a policy-safe message, and function names with line numbers but not source-file paths.

## What changed

- The native slider/spinner pair now has one committed-value owner, restores it after a failed transaction, ignores identical commits, and cancels pending spinner work when the App closes or a slider release supersedes it.
- Runtime control entry points skip bound no-ops before opening an operation and correlate the surviving interaction directly with its semantic callback alias.
- Ordinary callback transactions retain the semantic action boundary and one presentation-start checkpoint instead of seven automatic DEBUG/TRACE records.
- Session memory and viewer projection use 512-record and 512 KiB serialized bounds. Journals retain at most five 10 MiB segments and 50 MiB per session, while the root retains at most 100 sessions or 500 MiB by removing oldest closed sessions only.
- Warning preflush and durable breadcrumbs no longer duplicate manifest writes. A manifest still updates on ordinary buffered flush, retention/degradation changes, and orderly close.
- DIC, Batch Crop, Curvature Measurement, and Video Marker stopped logging ordinary parameter assignment or navigation as INFO. Video-render heartbeats are DEBUG developer progress, and retained App attributes no longer contain alignment metrics or output paths.
- CIC and VT Resistance keep their automatic batch refresh, but it now runs once for the SDK-committed final value instead of once per native spinner repeat; ordinary successful setting changes no longer emit INFO records.
- Public help, framework and App-authoring guides, scoped AGENTS rules, the App Builder Skill, and focused tests now state the same commit, refresh, busy, severity, payload, and retention constraints.

## Impact

Dragging a slider no longer changes scientific or workflow state until release and produces one transaction for the accepted final value. Rapid spinner repeats remain visually responsive but produce one transaction after the user pauses. Direct manipulation continues without busy flicker. Session logs remain useful for reconstructing semantic actions, phases, failures, correlation, and persistence health without retaining sensitive source identity or scientific content.

## Compatibility and limits

Layout declarations and callback signatures are unchanged, and final committed values produce the same App calculations as before. Apps that intentionally depended on every intermediate slider or spinner value must move that behavior to a bounded native-style preview or an explicit action. Spinner state publication trails its visible value by one second. Automated hidden-GUI tests verify callback timing and event counts; subjective pointer and repeated-click feel remains a manual MATLAB interaction check.
