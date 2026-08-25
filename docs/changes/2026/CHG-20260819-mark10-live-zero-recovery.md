# Keep Mark-10 zero recovery consistent with the live readout

```labkit-change
id: CHG-20260819-mark10-live-zero-recovery
date: 2026-08-19
type: fix
compatibility: compatible
component: labkit_Mark10Monitor_app | 1.0.1 -> 1.0.2
```

## Why

The Mark-10 Monitor reported a verified force zero but retained the preceding force value in the live readout. Its diagnostics also mixed current-failure and historical-failure behavior, and the callbacks lived in a generic technical package instead of their owning device capabilities.

### Accepted choice

A verified hardware result now updates the corresponding live value and clears the current unresolved failure. Manual reads belong to live acquisition, while verified device-zero operations belong to connection capability. This keeps the visible device state, recovery status, and code ownership consistent.

## What changed

Successful force zero stores the verified readback in the live force value and clears the current failure. The diagnostics title now states that it shows the current failure. Mark-10 read-once and zero callbacks moved from the generic actions package to acquisition and connection, and a repository guard prevents generic technical App packages from returning.

## Impact

After a successful force zero, operators immediately see the verified force value and no stale failure remains. Failed zero operations still preserve live values, retained recordings, plots, and exports. Existing recordings and exported data are unchanged.

## Compatibility and limits

The App entrypoint, controls, facade calls, saved-data behavior, and export formats remain compatible. No project or data migration is required.

### Remaining limits

Automated tests use a synthetic transport and do not prove physical serial-port exclusivity, unloaded-fixture safety, or real-device command authorization. Those remain operator checks before release.
