# NI-DMM discovery and repeat recording recovery

```labkit-change
id: CHG-20260910-ni-dmm-discovery-and-repeat-recording
date: 2026-09-10
type: fix
compatibility: compatible
component: labkit.nidmm | 1.0.0 -> 1.1.0
component: labkit_NIDMMRecorder_app | 1.0.0 -> 1.1.0
```

## Why

The initial recorder required operators to know a NI MAX resource alias and left interval-trigger state active after stopping buffered acquisition. A later automatic-range configuration then failed until the device was disconnected. Requested rates also needed an explicit relationship to the measurement period selected by the hardware, and stopped recordings could retain row-oriented plot vectors that made the recent-data table fail to render.

## What changed

- Added non-opening local NI-DMM discovery through the end-user-installed NI System Configuration .NET API and replaced free-text resource entry with an automatically populated device choice.
- Restored immediate trigger state before automatic ranging and after buffered acquisition stops, and reserved bounded driver-buffer headroom across fast and slow resolutions, allowing repeated reads and recordings on one connection.
- Reconciled the requested rate with the applied device measurement period and retained requested, target, and observed rate meaning separately.
- Normalized retained plot vectors at the recent-data presentation boundary so stopping a populated recording cannot roll back after releasing its sampling resource.
- Preserved a controlled NI numeric error code in facade failures while keeping vendor objects and unrestricted messages inside the private adapter.

## Impact

Operators can select a discovered DMM without knowing its NI MAX alias. A connected recorder can stop, change settings, read, and start again without a disconnect/reconnect cycle. Slow high-resolution configurations continue recording at a clearly reported device-limited target rather than implying an unattainable requested rate.

## Compatibility and limits

Existing facade callers remain source compatible within the `>=1 <2` range. Device discovery additionally requires NI System Configuration support installed by the operator. Discovery does not open or reset hardware, and each physical DMM remains exclusive to one process.
