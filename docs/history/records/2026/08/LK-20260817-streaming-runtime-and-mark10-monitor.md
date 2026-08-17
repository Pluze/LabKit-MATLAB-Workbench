# Streaming runtime support and Mark-10 force/travel monitoring

```labkit-change
id: LK-20260817-streaming-runtime-and-mark10-monitor
date: 2026-08-17
sequence: 178
type: feat
compatibility: compatible
component: `labkit.app` | `2.3.0 -> 2.4.0`
component: `labkit.mark10` | `new -> 1.0.0`
component: `labkit_Mark10Monitor_app` | `new -> 1.0.0`
scope: Background acquisition and streaming state publication
scope: Optional project persistence and precise dirty state
scope: Mark-10 ESM303 and Series 5 monitoring
scope: Standard CSV, MESUR gauge LOG, MAT export, and replay
scope: Per-branch stiffness and engineering modulus analysis
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
- Posted stream refreshes do not enter the user-action busy lifecycle, set the
  watch pointer, or disable controls while monitoring continues.
- Complete snapshots remain the App authoring contract, while the private
  native reconciler applies only operations whose values changed. Unchanged
  plots, tables, choices, text, and enabled states perform no native write.
- Successful presentation boundaries are TRACE-only so an ordinary streaming
  session does not serialize and journal two DEBUG records for every display
  refresh. Presentation failures remain ERROR records with their nested
  operation context.
- The live session viewer batches subscribed records into at most 10 native
  table updates per second instead of filtering, styling, and scrolling the
  complete visible projection once per incoming TRACE record.
- Session-only transactions no longer mark project documents dirty.
- `labkit.mark10` adds port discovery, connect/disconnect, synchronized sample
  reads with fallback, LIST decoding, safe setting readback, verified
  force/travel zero behavior, and paced sampling. One facade-owned Base MATLAB
  background worker exclusively owns the serial port while sampling, follows
  absolute deadlines, timestamps complete responses, and sends bounded batches
  to a lightweight client delivery timer. Sampling stop flushes the final batch
  and leaves the connection open.
- Mark-10 Monitor adds explicit live monitoring with in-memory retention, safe
  settings, standard CSV, MESUR gauge-compatible LOG, complete MAT export, and
  offline replay without a separate recording state.
- A connected-idle **Read Once** action updates only the live force/travel
  readout. Force Zero and Travel Zero are verified device operations; an
  unavailable ESM303 hardware `z` command fails without applying an App-local
  offset to live values, retained samples, analysis, or exports.
- The driver enforces and verifies Series 5 `IPOL1` at connection and before
  sampling, making tension positive and compression negative in device serial
  output, live views, retained data, exports, analysis, and replay.
- The monitor uses 10--50 Hz acquisition with a 50 Hz default. Its paced
  producer writes every completed response to memory, while an independent
  latest-value consumer caps presentation at 10 Hz, coalesces pending
  refreshes, reuses plot objects, and shows
  dual-axis time series above the standard force-versus-travel curve.
- Loading a recording displays complete curves immediately; Reset restores
  that view, Play restarts a 10-frame-per-second replay, and Pause toggles
  resume. Live and replay use the same deterministic range updater: 10 mm and
  1 N are empty-stream defaults, then signal dynamics and estimated sample rate
  determine populated headroom. Limits remain unchanged until a sample
  crosses the viewport, then refit tightly with a small margin. Non-pickable
  clipped traces remain
  compatible with MATLAB's
  axes-toolbar navigation, and both panels can explicitly refit X and
  independent Y limits. Exactly vertical force/travel segments are retained
  as points but disconnected from the continuous UIAxes trace to avoid MATLAB
  extending them outside the plot.
- Official LOG loading converts the declared file units once per column while
  preserving the driver decoder's exact unit factors, avoiding per-row
  protocol parsing during file import.
- Replay controls now live under **Analysis**. Complete loaded or stopped live
  recordings share one branch segmentation and fitting path. Automatic or
  branch-local manual regions produce stiffness, engineering Young's modulus,
  R², review status, stress-strain plots, statistics, and standard CSV.
  Gauge length, width, and thickness are explicit mm inputs, and geometry must
  be reviewed before calculation.
- Pending force and travel zero levels apply together on explicit request,
  shifting both live/replay plots and the shared modulus coordinates without
  rewriting recordings or changing fitted modulus. Reset immediately restores
  both plots and baselines, and modulus CSV records the applied levels as
  calculation provenance.
- Manual modulus fitting uses one applied-zero travel window across every
  branch instead of reinterpreting the window from each branch start. Branches
  outside that window remain explicit result rows without fabricated fit
  graphics; automatic endpoints use the same corrected coordinate. Four
  distinct fit coordinates retain two residual degrees of freedom for sparse
  resolved branches, while the R-squared acceptance gate remains unchanged.
- Plot popouts copy every visible graphics child even when its handle is
  hidden from ordinary discovery. Modulus fits keep every branch line and
  endpoint marker in the standalone figure while suppressing duplicate legend
  entries independently.
- Series 5 settings are grouped like the official Gauge Settings workflow.
  Dropdowns pair readable meaning with the exact `LIST`/GCL2 token while the
  driver continues to receive canonical values.
- Public-App headless conformance creates and presents every initial session,
  catching presenter parser/runtime failures before hidden-GUI smoke tests.

## User and data impact

Live Apps can refresh state without private UI access or false unsaved-project
prompts. Mark-10 users can monitor and retain force/travel while leaving stand
motion under existing hardware controls. Clean CSV and LOG omit invalid sample
attempts; MAT retains validity, acquisition mode, settings, and diagnostics.
Exports can include device metadata and should be reviewed before sharing.
Modulus CSV retains every branch and review flag. The engineering estimate
assumes a rectangular initial area and does not compensate fixture or specimen
compliance.

## Compatibility and migration

The App SDK addition remains in the version-2 compatibility range. Existing
Apps need no callback or project migration. The new driver and App begin at
version 1.0.0 and introduce no saved-project format because the monitor is
intentionally session-only.

## Validation

Focused SDK specifications cover validation, coalescing, close behavior,
session-only dirty state, unchanged native-operation suppression, semantic
control updates, and complete plot-popout copying. Offline Mark-10
specifications cover response contamination, unit normalization, LIST parsing,
fallback transactions, Base MATLAB background-worker ownership, and facade
metadata. App result specifications cover exact LOG bytes, CSV/LOG/MAT
reopen, replay rate mapping, acquisition-source replacement, and retained
samples, strict device-only travel zero, and refusal to send `z` without
confirmed command access; headless Runtime construction covers the complete
App definition and initial lifecycle.

## Evidence

- All 34 focused App SDK identities passed on MATLAB R2026a, including
  coalescing, active-transaction deferral, queued failure isolation, rollback,
  close, dirty state, and hidden-handle plot copying.
- Nine Mark-10 facade identities and 24 affected App capability identities
  passed without hardware.
- A profiler-backed hidden-UI probe updated both 2000-point live plots 20 times
  with a 2.32 ms mean wall-clock update, leaving substantial margin inside the
  100 ms presentation period after one-time axes and legend construction.
- A 12-second approved-device probe of the delivered facade retained 606 of
  606 valid synchronized samples over 12.117 seconds at 50.012 Hz while the
  client incurred 32 simulated 90 ms GUI stalls. The largest worker sample gap
  was 33.8 ms, all 606 queued samples arrived, and the device's measured
  continuous-read ceiling was 63.95 Hz.
- An anonymized pre-change device diagnostic contained no errors but measured
  two Start Monitoring interactions at 1.42 and 10.97 seconds. Sampling now
  leaves serial reads on the background worker while the client publishes and
  renders its state independently.
- All 66 public-App definition identities passed with the new App discovered
  from its normal launcher path.
- Documentation rendered deterministically to 408 generated files.

## Known limitations and follow-up

Automated tests do not prove physical cabling, serial-port exclusivity,
fixture safety, hardware zero load, stand mode, subjective plot quality, or
the visible App's perceived Start Monitoring responsiveness after the timer
migration. Developer-led visible-App confirmation remains required before
release. The App does not send stand motion, limit, cycle, or automatic `SAVE`
commands.
