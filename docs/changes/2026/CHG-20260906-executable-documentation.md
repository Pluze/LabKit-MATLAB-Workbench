# Validate executable documentation against current APIs

```labkit-change
id: CHG-20260906-executable-documentation
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit.app | 3.4.0 -> 3.4.1
component: labkit.dta | 3.1.1 -> 3.1.2
component: labkit.rhs | 1.0.4 -> 1.0.5
component: labkit.thermal | 1.1.3 -> 1.1.4
component: labkit.mark10 | 1.0.1 -> 1.0.2
component: labkit_ROIAnalyzer_app | 1.1.0 -> 1.1.1
component: labkit_ECGPrint_app | 2.2.0 -> 2.2.1
```

## Why

Documentation promised runnable examples, but rendering and deterministic-byte checks did not execute them. Stale compatibility, ROI geometry, and minimal-App examples could therefore pass the documentation gate.

## What changed

docsCheck discovers runnable examples from the public API/page model and executes them in fresh workspaces and temporary folders before rendering. Runtime failures, empty examples, and malformed marked fences fail the check. External-input sketches use Typical Call. Current compatibility, callback capability, ROI, curvature, ECG selector, and journal-retention documentation is reconciled with source.

## Impact

Readers receive examples checked against the current implementation, and documentation-tool changes have source-owned regression tests. Public computation and SDK runtime behavior are unchanged.

## Compatibility and limits

The runner executes trusted repository code in MATLAB; it is not a sandbox or a proof of scientific validity. Interactive, device, and user-file workflows remain outside automated example evidence. Persistent MATLAB state and external side effects are not isolated by a function workspace.
