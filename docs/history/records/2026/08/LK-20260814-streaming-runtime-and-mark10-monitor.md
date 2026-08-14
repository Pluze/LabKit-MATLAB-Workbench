# Streaming runtime support and Mark-10 force/travel monitoring

```labkit-change
id: LK-20260814-streaming-runtime-and-mark10-monitor
date: 2026-08-14
sequence: 178
type: feat
compatibility: compatible
component: `labkit.app` | `2.3.0 -> 2.4.0`
component: `labkit.mark10` | `new -> 1.0.0`
component: `labkit_Mark10Monitor_app` | `new -> 1.0.0`
scope: Generic timer and streaming state publication
scope: Optional project persistence and precise dirty state
scope: Mark-10 ESM303 and Series 5 monitoring
scope: Standard CSV, MESUR gauge LOG, MAT export, and replay
```

## Context

Live serial, network, monitor, and dashboard Apps need background producers to
request state and plot refresh without mutating native controls or retaining
private Runtime handles. Treating every App transaction as a project change
also made transient dashboards look unsaved. Mark-10 ESM303 and Series 5
hardware additionally needed one reusable protocol owner and a safe App that
does not operate stand motion.

## Decision and rationale

Add one protocol-neutral posted-event method to the existing callback context.
Coalesce by semantic event ID and execute the latest update through the normal
Runtime transaction, while keeping producer protocol, buffering, and retry
policy outside the SDK. Mark documents dirty only when the validated project
value changes. Put Mark-10 framing and settings in a GUI-free facade, and keep
recording, replay, export format, plots, controls, and safety wording in the
Force Gauges App.

## Changes

- `CallbackContext.postEvent` supports timer, serial, TCP, UDP, and other
  stream producers through one fixed state-update callback.
- Pending posts with the same ID are latest-wins coalesced, serialized,
  validated, presented, diagnosed, rolled back on failure, and ignored after
  close. Posts remain in the coalescing pump while a user transaction is
  active, preventing a continuous producer from extending that transaction.
- Session-only transactions no longer mark project documents dirty.
- `labkit.mark10` adds port discovery, connect/disconnect, synchronized sample
  reads with fallback, LIST decoding, safe setting readback, and verified
  force/travel zero behavior.
- Mark-10 Monitor adds live plotting, independent recording, safe settings,
  standard CSV, MESUR gauge-compatible LOG, complete MAT, and offline replay.
- The monitor uses 10--50 Hz acquisition with a 50 Hz default, caps its
  presentation cadence at 30 Hz, reuses plot objects, and shows
  dual-axis time series above the standard force-versus-travel curve.
- Loading a recording displays complete curves immediately; Reset restores
  that view, Play restarts a 10-frame-per-second replay, and Pause toggles
  resume. Live and replay use the same buffered range updater: 10 mm and 1 N
  are empty-stream defaults, then signal dynamics and estimated sample rate
  determine later headroom so limits change only after data leaves the current
  range. Non-pickable clipped traces remain compatible with MATLAB's
  axes-toolbar navigation, and both panels can explicitly refit X and
  independent Y limits. Exactly vertical force/travel segments are retained
  as points but disconnected from the continuous UIAxes trace to avoid MATLAB
  extending them outside the plot.
- Official LOG loading converts the declared file units once per column while
  preserving the driver decoder's exact unit factors, avoiding per-row
  protocol parsing during file import.

## User and data impact

Live Apps can refresh state without private UI access or false unsaved-project
prompts. Mark-10 users can monitor and record force/travel while leaving stand
motion under existing hardware controls. Clean CSV and LOG omit invalid sample
attempts; MAT retains validity, acquisition mode, settings, and diagnostics.
Exports can include device metadata and should be reviewed before sharing.

## Compatibility and migration

The App SDK addition remains in the version-2 compatibility range. Existing
Apps need no callback or project migration. The new driver and App begin at
version 1.0.0 and introduce no saved-project format because the monitor is
intentionally session-only.

## Validation

Focused SDK specifications cover validation, coalescing, close behavior, and
session-only dirty state. Offline Mark-10 specifications cover response
contamination, unit normalization, LIST parsing, fallback sampling, and facade
metadata. App result specifications cover exact LOG bytes, CSV/LOG/MAT reopen,
and replay rate mapping; headless Runtime construction covers the complete App
definition and initial lifecycle.

## Evidence

- All 24 App SDK headless identities passed on MATLAB R2026a, including
  coalescing, active-transaction deferral, queued failure isolation, rollback,
  close, and dirty state.
- Five Mark-10 facade identities and seventeen App capability identities passed
  without hardware.
- All 44 public-App definition identities passed with the new App discovered
  from its normal launcher path.
- Documentation rendered deterministically to 405 generated files.

## Known limitations and follow-up

Automated tests do not prove physical cabling, serial-port exclusivity,
fixture safety, hardware zero load, stand mode, or subjective plot quality.
Developer-led testing on an approved device remains required. The App does not
send stand motion, limit, cycle, or automatic `SAVE` commands.
