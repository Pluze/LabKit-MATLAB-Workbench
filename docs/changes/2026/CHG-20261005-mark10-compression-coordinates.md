# Define Mark-10 geometry, strain fitting, and data review

```labkit-change
id: CHG-20261005-mark10-compression-coordinates
date: 2026-10-05
type: feat
compatibility: breaking
component: labkit_Mark10Monitor_app | 1.2.0 -> 2.0.0
component: labkit.app | 3.4.1 -> 3.5.0
```

## Why

Force/travel recordings use full fixture closure as travel zero, while material zero strain occurs at the specimen's initial effective length. Treating travel as extension obscured that distinction. Rectangular-only geometry, travel-based fitting windows, and unreviewed force spikes also made comparisons across specimen shapes and lengths difficult.

## What changed

Tension, Compression, and Cyclic share the closed-fixture gap reference. Compression strain is positive shortening; tension and cyclic strain are signed extension from reviewed initial length. A sustained-force locator identifies the initial loading ramp; a low-load force/gap fit extrapolates to zero force for editable, explicit initial-length review. Contact-reference and analysis time intervals are independently selectable. Cross-section input offers Length x width by default, Radius, or directly entered Area. An editable table of manual strain windows replaces automatic/single-region selection. Each branch/window retains its signed computable slope regardless of R², with coverage and diagnostic notes. Modulus display supports automatic common-unit selection or manual kPa, MPa, and GPa without recalculation. Optional glitch detection reports isolated force/travel excursions and can exclude them from estimation and analysis while preserving raw recordings.

A synchronized auxiliary diagnostic window displays reference fitting and curve validity. Export Stress-Strain CSV writes full-resolution selected-time curves independently of modulus fitting. Loaded filenames appear in the window and plot headings. The SDK adds `Snapshot.windowSubtitle` so the runtime owns title reconciliation, busy feedback, and rollback while the App owns the filename label; `Snapshot.renderPlot` adds a counter-driven `WindowRequest` with runtime-owned auxiliary window lifetimes.

## Impact

Users review fixture zero, initial length, area, glitches, and strain windows and their actual coverage before reporting modulus. See the [Mark-10 manual](../../use/apps/force-gauges/mark10-monitor/README.md#zero-reference-and-initial-length) for equations, estimation rules, and the complete workflow.

## Compatibility and limits

Raw CSV, LOG, and MAT recordings are unchanged. Export Stress-Strain CSV replaces the old modulus-summary export with `Time_s`, dimensionless `Strain`, and `Stress_MPa`; downstream consumers must use the new schema. Generic / Other is removed from the transient selector; Tension is the default. Existing raw travel must use or be offset to the closed-fixture reference. Analysis settings are transient, so no saved analysis-session migration is required.

Extrapolated length requires review and is not an independent dimension measurement. Failed extrapolation does not silently substitute a threshold length. Glitch detection can flag genuine narrow peaks or miss sustained corruption. Low R² remains visible because nonlinear/viscoelastic responses can still support useful interval slopes; no R² cutoff establishes physical linearity or corrects machine compliance. These changes do not establish real-device validation.
