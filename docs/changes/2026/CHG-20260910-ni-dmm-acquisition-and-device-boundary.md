# NI-DMM acquisition and explicit device dependency boundary

```labkit-change
id: CHG-20260910-ni-dmm-acquisition-and-device-boundary
date: 2026-09-10
type: feat
compatibility: compatible
component: labkit.nidmm | new -> 1.0.0
component: labkit_NIDMMRecorder_app | new -> 1.0.0
component: labkit.mark10 | 1.0.2 -> 1.1.0
component: labkit_Mark10Monitor_app | 1.1.2 -> 1.2.0
```

## Why

Public Apps needed NI 4065 acquisition without making vendor APIs an undeclared App dependency. NI resistance measurements also needed timestamps that can be aligned with independently sampled Mark-10 force and travel.

### Accepted choice

Keep Apps limited to Base MATLAB, their own package, and declared LabKit facades. Isolate the user-installed NI-DMM .NET API inside one counted private `labkit.nidmm` adapter, validate it before hardware access, and expose only MATLAB-native values. Use a common host UTC representation with explicit uncertainty instead of claiming unavailable hardware-clock synchronization.

## What changed

- Added the `labkit.nidmm` facade for runtime checks, connection, generic DMM configuration, single reads, and buffered acquisition.
- Added NI-DMM Recorder with 10--50 Hz requested rates, live status, UTC-aware retention, and CSV/MAT export.
- Added UTC receipt estimates and uncertainty to Mark-10 samples and exports.
- Added exact codecheck enforcement so no App or unrelated facade can call the vendor API.

## Impact

An NI-DMM and Mark-10 can record concurrently in one MATLAB instance and their exports can be aligned by host UTC. Missing NI software becomes a supported diagnostic rather than an App crash. Existing Mark-10 readers remain valid because the new sample fields and export columns are additive.

## Compatibility and limits

NI USB-4065 access requires 64-bit Windows and the end-user-installed NI-DMM .NET runtime. The instruments do not share a hardware clock or trigger, so synchronization is bounded host-time alignment. A physical device remains exclusive to one process. Two manually opened MATLAB instances can isolate different devices but must not attempt to share one resource.
