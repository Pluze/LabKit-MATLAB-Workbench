# Mark-10 Force/Travel Monitor

```labkit-page
id: app-mark10-monitor
type: landing
audience: app-user
summary: Monitor and replay ESM303 force and travel data, then calculate engineering stress–strain curves and strain-window moduli without controlling stand motion.
```

Mark-10 Monitor connects to an ESM303 with an attached Series 5 gauge, displays and retains live force and travel without controlling stand motion, replays previously exported data, and calculates engineering stress–strain curves and strain-window moduli.

The central workspace follows the official monitoring workflow with separate **Live Plots**, **Recent Data**, and **Modulus Analysis** pages. The upper live plot combines travel and force against time on two Y axes; the lower plot is the standard force-versus- travel curve. The table shows the latest 200 valid visible samples while the full monitoring run remains in the managed buffer.

Connection, settings, read-once, playback, and monitoring controls call their owned workflow directly, while retained samples remain the single source for plots and export.

The control side is split into task-focused **Monitor**, **Analysis**, and **Settings** tabs. Connection, live monitoring/export, file playback, and device configuration therefore remain independent instead of sharing one long scrolling panel.

## Connect, Monitor, And Export

Run `labkit_Mark10Monitor_app`, choose **Refresh Ports**, select the serial port, and choose **Connect**. Connection only opens and probes the device; choose **Start Monitoring** to begin live reads. **Stop Monitoring** stops reads while keeping the serial connection open. Starting a monitoring run clears the preceding in-memory run, then retains every sample attempt while updating the plots. Choose **Export CSV + LOG + MAT** to save that retained run; no separate recording mode is required.

While connected and not monitoring, **Read Once** requests one synchronized force/travel sample and updates only **Live Readout**. It does not start a run, append to the monitoring buffer, or change export eligibility.

Choose 10, 20, 30, 40, or 50 Hz paced acquisition; 50 Hz is the default. Measured rate is shown instead of assuming the requested value. One facade-owned Base MATLAB background worker exclusively owns the serial port while monitoring, follows absolute sample deadlines, and returns completed samples in bounded batches. A slow response may therefore be followed by an immediate real read to recover the requested average rate; no sample or timestamp is fabricated. The App retains every completed attempt but refreshes plots, controls, and diagnostics at no more than 10 frames per second. Only one unhandled display refresh is queued, keeping presentation work bounded ahead of **Stop Monitoring** or the Tools menu. Stopping flushes the final sample batch, commits one final buffer snapshot, and keeps the serial port connected.

The ESM303 `n` response does not include a device timestamp. Recorded `Time_s` is the monotonic host time when the complete force/travel response is accepted; `TimestampUTC` and `TimeUncertainty_s` provide a bounded host-clock estimate for alignment with NI-DMM Recorder. These fields include communication timing and are independent of the lower GUI frame rate; they are not hardware-trigger synchronization. The App uses synchronized `n` reads and reports invalid or timed-out responses without fabricating force/travel values. Force uses one convention everywhere: tension is positive and compression is negative. Connect and Start Monitoring verify the gauge's `IPOL1` output setting, so live values, exports, replay, and device serial output agree. Plot limits stay fixed while new samples remain visible. A sample outside the current viewport triggers one tight refit with a small margin; the explicit **Refit Plot Limits** action uses the same rule. Monitoring, stopped data, and replay therefore share one range policy without recomputing axes every frame.

**Zero Force** verifies the Series 5 device zero against its displayed resolution and immediately updates the live force readout from the verified device value. **Zero Travel** sends the ESM303 hardware `z` command only when stand status proves that command path is available, then verifies the device travel reading. If hardware zero cannot be verified, the action fails and the App does not alter live values, retained samples, plots, or exports with a software offset. The App never sends UP, DOWN, motion speed, limit, cycle, or automatic `SAVE` commands.

The Diagnostics panel reports the current unresolved device failure. A later successful read, verified zero, or complete settings apply clears it so recovered operations do not leave a stale failure visible.

## Exported Data

One export writes three data files:

- standard CSV with `TimestampUTC`, `Time_s`, `Force_N`, `Travel_mm`, and `TimeUncertainty_s`;
- a tab-delimited MESUR gauge-compatible `.log` with the official six-line header, CRLF line endings, and `Reading`, `Load`, `Travel`, `Time` columns;
- MAT with the complete sample attempts, normalized and device-native values and units, validity, acquisition modes, settings, experiment label, requested rate, and connection diagnostics.

The LOG uses N and mm consistently. Invalid attempts remain in MAT but are omitted from the clean CSV and LOG.

## Load, Replay, And Analyze

Disconnect hardware, choose **Load**, and select an App CSV, MESUR gauge LOG, or complete MAT export. Load immediately displays the complete curves. **Reset** stops replay and restores that complete view. **Play from Start** always begins at the first sample; **Pause / Resume** retains and resumes the current cursor. Replay uses a fixed 10-frame-per-second visual progression of approximately ten seconds rather than recorded timestamps. Live acquisition and replay derive limits from the same currently displayed sample prefix. Empty plots begin with 10 mm travel and 1 N force headroom; populated plots use recent sample changes, observed span, signal level, and acquisition rate. The result does not depend on earlier refreshes. **Refit Plot Limits** reapplies that deterministic range after manual pan or zoom, including the independent travel and force Y limits in the upper plot; it is available during both live monitoring and replay. Select MATLAB's Pan tool in an axes toolbar when drag panning is needed. Hardware connection is disabled during replay and replay controls are disabled while connected.

The **Analysis** tab uses the complete loaded recording or valid samples of a stopped monitoring run, independently of the visible replay prefix. Loaded filenames appear in the App window, raw plot headings, and analysis headings. A new recording clears geometry confirmation and previous results.

## Analysis Workflow

Follow the numbered sections in the **Analysis** tab:

1. Load data, choose **Tension**, **Compression**, or **Cyclic**, and set the analysis start/end times in seconds. Times are original recording times. **Use Full Time Range** restores the source bounds. The overview marks the selected interval.
2. Review force zero and the closed-fixture travel reference. Optionally detect and exclude isolated glitches.
3. Choose a separate contact-reference time interval, estimate initial length by zero-force extrapolation or enter a measured value, review the cross-section, and confirm dimensions. Choose **Update Stress-Strain** to prepare the curve.
4. Add and edit one or more strain windows in percent, then choose **Calculate Window Moduli**. Inspect each branch/window result and its selected points. Open **Analysis Diagnostics** for a synchronized separate window.
5. Use **Export Stress-Strain CSV** at the bottom of the Analysis tab to save the prepared curve. Window fitting is not required for this export.

Changing a strain window clears only fitted results. Changing the analysis time interval clears the curve and fits while retaining the reviewed initial length and contact estimate. Changing the test type, applied zero, glitch exclusion, or contact-reference settings clears the estimate and geometry confirmation. Editing specimen dimensions clears confirmation and the curve. These changes require the relevant update/confirmation before another export; an open diagnostic window reflects the same state.

## Zero Reference And Initial Length

In every mode, corrected travel is the fixture gap: **0 mm means fully closed**. Set the travel offset to the recorded reading at full closure; leave it at 0 if the instrument already uses that reference. Set force zero from unloaded data, then choose **Apply Zero**. These offsets translate live/replay plots without changing raw recordings or their exports. Editing offsets changes draft values until applied. **Reset Zero** restores offsets to 0 and invalidates geometry and derived results.

The zero-strain position is the initial effective specimen length or height, not the closed fixture and not the recording's first point. Compression may approach from a larger gap; tension may start with slack. Enter measured initial length/height, or choose **Extrapolate Initial Length** after selecting a contact-reference interval that includes unloaded baseline and the initial loading ramp. This interval is independent of the time interval used for stress–strain analysis, so later loading or recovery can still use the original contact reference.

The estimator first locates sustained onset using a threshold initially set to 0.02 N. The interval's first 0.5 s, with at least eight samples, supplies an unloaded noise baseline. The effective onset threshold is the larger of the selected threshold and six robust standard deviations (`1.4826 * median absolute deviation`). Onset requires at least four consecutive above-threshold samples lasting 0.2 s, with travel moving in the loading direction. Compression uses negative force and decreasing gap; tension uses positive force and increasing gap; cyclic mode accepts a matching signed event.

The estimator then fits force magnitude against corrected gap on the associated low-load ramp and extrapolates that line to zero force. The initial force range is 0.002–0.04 N; review it for the gauge resolution and material. At least four samples at two distinct gaps are required. Pre-onset search is limited to 35 s and the nearest preceding below-range point; the post-onset search stops at the upper force bound, a motion reversal, or an acquisition gap. The displayed estimate includes the extrapolated length, threshold-onset gap, fit R², and sample count. A failed fit produces a reason, with no silent substitution of threshold length.

Review the fit in the diagnostics, correct the proposed length if needed, and explicitly confirm geometry. Extrapolation estimates an effective unloaded length; it can be biased by baseline drift, slack, fixture compliance, nonlinear contact, force range, or fixture-zero error. Neither a high R² nor force onset independently measures true specimen dimensions. A manual reviewed length is supported when estimation is unsuitable. Establish full closure independently of a specimen.

Let `gap = travel - travelOffset`, `F = force - forceZero`, and `L0` be the reviewed initial length or height:

| Test type | Engineering strain | Engineering stress (MPa) |
| --- | --- | --- |
| Tension | `(gap - L0) / L0` | `F / A0` |
| Compression | `(L0 - gap) / L0` | `-F / A0` |
| Cyclic | `(gap - L0) / L0` | `F / A0` |

Compression is positive in Compression mode. Cyclic mode retains tension-positive and compression-negative coordinates. Pre-contact/slack data remain in the chosen time interval; they are not automatically material fit regions. Plots and window inputs use percent strain; exported strain is a dimensionless fraction.

## Cross-Section And Strain Windows

**Cross-section input** defaults to **Length x width**. Only selected inputs are used. Axial initial length/height is independent of these section dimensions.

| Cross-section input | Required values | Area in mm² |
| --- | --- | --- |
| Length x width (default) | Section length and section width, mm | `length * width` |
| Radius | Radius, mm, not diameter | `pi * radius^2` |
| Area | Area, mm² | Entered value |

The window table contains **Use**, **Name**, **From %**, and **To %**. The initial manual window is 0–10%; this is an editable starting range, not a validated material linear region. Add/delete rows, enable only desired rows, or specify overlapping intervals such as 5–15%, 10–20%, and 20–30%. Negative bounds select compression in Cyclic mode. No automatic search substitutes a different strain range.

Each enabled window is fitted separately within each monotonic travel branch of the selected time interval. Motion reversals and long acquisition gaps separate branches; an isolated excluded glitch does not itself create a new branch. Loading and recovery are not pooled. The result table gives branch/direction, window name, requested and actual strain bounds, sample count, signed slope with its displayed unit, R², coverage, and notes. Select a result row to highlight its samples and fit line.

**Modulus display unit** defaults to **Auto**, with manual **kPa**, **MPa**, and **GPa** choices. Auto selects one common unit for the result table using the largest finite absolute modulus: below 1 MPa uses kPa, from 1 to below 1000 MPa uses MPa, and 1000 MPa or above uses GPa. Empty/all-zero results use kPa. The column heading identifies the selected unit. Changing display units preserves signed slopes, R², curve validity, and fitting choices; calculations and the stress–strain CSV retain MPa.

```text
stress (MPa) = mode-specific signed force (N) / initial area (mm^2)
window modulus (MPa) = fitted stress/strain slope, with a free intercept
```

Every computable slope is displayed, including low R², negative slopes, partial-window coverage, two-point fits, and zero slopes. R² below 0.95 is a descriptive review note only; it never suppresses a result or excludes it from an average. The App does not average branches. Constant stress has an undefined R² but a valid zero slope. Fewer than two distinct strain values produces NaN with an explanation. Partial coverage is identified rather than extending the fit beyond measured data. For nonlinear or viscoelastic materials, interpret the result as an apparent modulus over the stated interval and loading history, not proof of a globally linear elastic material.

## Optional Glitch Exclusion

**Detect Glitches** reports candidate counts and marks candidates on the raw overview. **Exclude isolated glitches** defaults to off. When enabled, whole synchronized samples flagged in either force or travel are omitted from length estimation, stress–strain conversion, and fitting. Raw recordings and live/replay curves remain intact. No replacement/interpolated values are fabricated.

Detection uses five neighbours on each side, a local median, and an eight-robust-standard-deviation threshold with minimum jumps of 0.02 N for force and 0.02 mm for travel. Before/after medians must agree within that threshold, retaining persistent steps. The first and last five points remain unassessed. Genuine narrow peaks can be flagged, while longer corruption or permanent offsets can remain. Review candidates before exclusion, particularly near fracture.

## Diagnostic Window And Export

**Analysis Diagnostics** opens a separate window with force/time, gap/time, contact extrapolation, and stress–strain plots. It reflects subsequent settings/results; invalidated curves show that an update is needed. Closing it leaves the main analysis active. It stays closed until requested again and closes with the App. The workspace also provides the diagnostic plots.

**Export Stress-Strain CSV** writes three columns: `Time_s`, `Strain`, and `Stress_MPa`. It includes every retained sample within the chosen analysis time range, in acquisition order, with applied zero, reviewed geometry, and optional glitch exclusion. It does not export display downsampling, extend to unmeasured strains, or depend on successful window fitting. The old modulus-summary CSV action is removed. Raw CSV/LOG/MAT export remains available from Monitor and is unchanged.

Connections, samples, playback, and analysis settings are transient. Closing does not save an analysis session. Record geometry, reference interval, window choices, and test conditions with any reported material results; the three-column curve export is not a complete processing archive.

## Gauge Settings

The settings tab follows the official Gauge Settings grouping: measurement and display choices are separate from RS-232 output and read/apply actions. It reads and verifies Series 5 unit, measurement mode, current and display filters, output format, and Auto Output. Every dropdown uses a readable label followed by its exact GCL2 token, such as **Peak tension (PT)** and **Numeric value + units (FULL)**. Filter labels show both the moving-average sample count and `FLTCn` or `FLTPn`; `n` is the protocol exponent and the sample count is `2^n`. These terms and values follow the Series 5 Gauge Settings screen, manual, and verified `LIST` probe behavior.

**Apply + Verify** checks each change with `LIST`. It does not persist settings with `SAVE`. Auto Output is held at zero during synchronous monitoring and restored on disconnect.

## Programmatic Driver

Use `labkit.mark10.connect`, `readSample`, `readSettings`, `writeSetting`, `zeroForce`, `zeroTravel`, and `disconnect` for GUI-free workflows. See the [Mark-10 driver manual](../../../../develop/libraries/mark10/README.md).

## Limitations

- Real serial-port exclusivity, cabling, fixture safety, and zero load must be checked by the operator.
- Identity and stand-status commands can be mode-dependent; readable force or travel remains the primary connection evidence.
- Reported modulus is an engineering estimate based on the selected initial cross-sectional area. It does not correct grip compliance, machine compliance, changing area, extensometer offset, viscoelastic rate effects, or specimen slip. Review branch segmentation and the fitted region before reporting material data.
- Hidden-GUI tests do not validate physical hardware behavior or subjective plot quality.

Loaded recordings show their filename, including extension, in the App window, raw plot headings, and Modulus Analysis heading. Loading another recording updates those labels; live monitoring clears the recording label.
