# Keep Mark-10 zero recovery consistent with the live readout

```labkit-change
id: LK-20260819-mark10-live-zero-recovery
date: 2026-08-19
sequence: 186
type: fix
compatibility: compatible
component: `labkit_Mark10Monitor_app` | `1.0.1 -> 1.0.2`
scope: Mark-10 force zero recovery
scope: App capability ownership
```

## Context

The Mark-10 Monitor reported a verified force zero but retained the preceding force value in the live readout. Its diagnostics also mixed current-failure and historical-failure behavior, and the callbacks lived in a generic technical package instead of their owning device capabilities.

## Decision and rationale

A verified hardware result now updates the corresponding live value and clears the current unresolved failure. Manual reads belong to live acquisition, while verified device-zero operations belong to connection capability. This keeps the visible device state, recovery status, and code ownership consistent.

## Changes

Successful force zero stores the verified readback in the live force value and clears the current failure. The diagnostics title now states that it shows the current failure. Mark-10 read-once and zero callbacks moved from the generic actions package to acquisition and connection, and a repository guard prevents generic technical App packages from returning.

## User and data impact

After a successful force zero, operators immediately see the verified force value and no stale failure remains. Failed zero operations still preserve live values, retained recordings, plots, and exports. Existing recordings and exported data are unchanged.

## Compatibility and migration

The App entrypoint, controls, facade calls, saved-data behavior, and export formats remain compatible. No project or data migration is required.

## Validation

Focused source specifications cover successful force-zero recovery, unavailable travel zero, manual read behavior, and the repository package-name guard. Final integration validation includes deterministic documentation, code analysis, and the changed-path pre-PR gate before required pull-request CI.

## Evidence

The successful recovery specification begins with an earlier failure and a nonzero live force, then verifies the device readback becomes the displayed value and the failure clears. The repository architecture specification scans every App package against the governed technical-name list.

## Known limitations and follow-up

Automated tests use a synthetic transport and do not prove physical serial-port exclusivity, unloaded-fixture safety, or real-device command authorization. Those remain operator checks before release.
