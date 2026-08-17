# Mark-10 Force/Travel Monitor

Mark-10 Monitor connects to an ESM303 with an attached Series 5 gauge,
displays and retains live force and travel without controlling stand motion,
replays previously exported data, and estimates branch stiffness and
engineering Young's modulus.

The central workspace follows the official monitoring workflow with separate
**Live Plots**, **Recent Data**, and **Modulus Analysis** pages. The upper live
plot combines travel and
force against time on two Y axes; the lower plot is the standard force-versus-
travel curve. The table shows the latest 200 valid visible samples while the
full monitoring run remains in the managed buffer.

The control side is split into task-focused **Monitor**, **Analysis**, and
**Settings** tabs. Connection, live monitoring/export, file playback, and
device configuration therefore remain independent instead of sharing one
long scrolling panel.

## Connect, Monitor, And Export

Run `labkit_Mark10Monitor_app`, choose **Refresh Ports**, select the serial
port, and choose **Connect**. Connection only opens and probes the device;
choose **Start Monitoring** to begin live reads. **Stop Monitoring** stops
reads while keeping the serial connection open. Starting a monitoring run
clears the preceding in-memory run, then retains every sample attempt while
updating the plots. Choose **Export CSV + LOG + MAT** to save that retained
run; no separate recording mode is required.

While connected and not monitoring, **Read Once** requests one synchronized
force/travel sample and updates only **Live Readout**. It does not start a run,
append to the monitoring buffer, or change export eligibility.

Choose 10, 20, 30, 40, or 50 Hz paced acquisition; 50 Hz is the default.
Measured rate is shown instead of assuming the requested value. One persistent
background driver owns the port, requests and timestamps synchronized samples,
and sends them to the App in batches. The App retains every delivered attempt
but refreshes plots, controls, and diagnostics at no more than 2 frames per
second. Only one unhandled display refresh is queued, so rendering cannot set
the acquisition pace or build a presentation backlog ahead of **Stop
Monitoring** or the Tools menu. Stopping flushes the driver's final batch and
commits one final buffer snapshot while keeping the port connected.

The ESM303 `n` response does not include a device timestamp. Recorded `Time_s`
is the background driver's monotonic host time when the complete force/travel
response is accepted; it includes communication latency and is independent of
batch delivery and the lower GUI frame rate. The App uses synchronized `n`
reads and reports invalid or timed-out responses without fabricating
force/travel values. Force uses one convention everywhere: tension is positive
and compression is negative. Connect and Start Monitoring verify the gauge's
`IPOL1` output setting, so live values, exports, replay, and device serial
output agree.
Plot limits stay fixed while new samples remain visible. A sample outside the
current viewport triggers one tight refit with a small margin; the explicit
**Refit Plot Limits** action uses the same rule. Monitoring, stopped data, and
replay therefore share one range policy without recomputing axes every frame.

**Zero Force** verifies the Series 5 zero against its displayed resolution.
**Zero Travel** uses hardware zero only when stand status proves that command
path is available; otherwise it applies a visible and exported software-zero
offset. A successful software zero immediately shifts the live readout and
displayed live curve, including while monitoring is stopped. The App never
sends UP, DOWN, motion speed, limit, cycle, or automatic
`SAVE` commands.

## Gauge Settings

The settings tab follows the official Gauge Settings grouping: measurement
and display choices are separate from RS-232 output and read/apply actions.
It reads and verifies Series 5 unit, measurement mode, current and display
filters, output format, and Auto Output. Every dropdown uses a readable label
followed by its exact GCL2 token, such as **Peak tension (PT)** and **Numeric
value + units (FULL)**. Filter labels show both the moving-average sample count
and `FLTCn` or `FLTPn`; `n` is the protocol exponent and the sample count is
`2^n`. These terms and values follow the Series 5 Gauge Settings screen,
manual, and verified `LIST` probe behavior.

**Apply + Verify** checks each change with `LIST`. It does not persist settings
with `SAVE`. Auto Output is held at zero during synchronous monitoring and
restored on disconnect.

## Exported Data

One export writes three data files and a LabKit manifest:

- standard CSV with `Time_s`, `Force_N`, and `Travel_mm`;
- a tab-delimited MESUR gauge-compatible `.log` with the official six-line
  header, CRLF line endings, and `Reading`, `Load`, `Travel`, `Time` columns;
- MAT with the complete sample attempts, normalized and device-native values
  and units, validity, acquisition modes, settings, experiment label,
  requested rate, and connection diagnostics.

The LOG uses N and mm consistently. Invalid attempts remain in MAT but are
omitted from the clean CSV and LOG.

## Load, Replay, And Analyze

Disconnect hardware, choose **Load**, and select an App CSV, MESUR gauge LOG,
or complete MAT export. Load immediately displays the complete curves.
**Reset** stops replay and restores that complete view. **Play from Start**
always begins at the first sample; **Pause / Resume** retains and resumes the
current cursor. Replay uses a fixed 10-frame-per-second visual progression of
approximately ten seconds rather than recorded timestamps. Live acquisition
and replay derive limits from the same currently displayed sample prefix.
Empty plots begin with 10 mm travel and 1 N force headroom; populated plots use
recent sample changes, observed span, signal level, and acquisition rate. The
result does not depend on earlier refreshes. **Refit Plot Limits** reapplies
that deterministic range after manual pan or zoom, including the independent
travel and force Y limits in the upper plot; it is available during both live
monitoring and replay. Select MATLAB's Pan tool in an axes toolbar when drag
panning is needed. Hardware connection is disabled during replay and replay
controls are disabled while connected.

The **Analysis** tab also calculates one fit for each sufficiently long
monotonic travel branch. This shared path accepts either a complete loaded
CSV/LOG/MAT recording or the complete valid sample buffer from a stopped
monitoring run. It does not fit only the currently visible replay prefix.
For a manual travel window, a branch needs at least four distinct travel
coordinates; accepted results must still meet the displayed R-squared quality
threshold.

**Plot Zero** accepts the raw force level in N and raw travel level in mm
that should be treated as zero. Editing only changes the pending values;
**Apply Zero** commits both values together, immediately translates force and
travel in the upper time-series plot and both coordinates in the lower
force-versus-travel plot, then refits their limits. Replay advancement and
live refresh continue using those applied levels. Modulus analysis uses the
same applied coordinates, so there is no second zero-point interpretation.
A constant zero shift changes coordinates and fitted intercepts but not the
stress/strain slope or Young's modulus. **Reset Zero** restores both applied
and pending levels to 0, immediately restores the two plots, and clears the
previous modulus result. Neither action modifies the source recording or the
standard CSV/LOG/MAT export.

Enter rectangular-specimen gauge length, width, and thickness in mm, then
select **Geometry reviewed**. Width and thickness are both required because
Young's modulus needs cross-sectional area; thickness alone is not silently
treated as area. The calculation uses:

```text
engineering strain = (travel - travel zero) / gauge length
engineering stress (MPa) = (force - force zero) / (width * thickness)
Young's modulus (MPa) = absolute fitted stress/strain slope
stiffness (N/mm) = Young's modulus * area / gauge length
```

Each branch retains the same corrected absolute stress-strain coordinates,
while region selection measures displacement from that branch's own start.
Taking the absolute fitted slope lets loading and recovery moduli be compared
even when their traversal directions differ. The selected experiment type
supplies tension/compression wording; the normal Mark-10
compression-positive polarity is used only to label a cyclic branch when no
single test direction applies. Raw measurements and recording exports are
never smoothed or rewritten.

**Automatic** fitting considers multiple contiguous regions from 5--35% to
45--85% of each branch's travel span, selects the best combination of
linearity and usable span, and marks fits with R² below 0.95 for review.
This avoids the initial toe region and the late peak/fracture region in common
tension, compression, and cyclic records. **Manual** fitting uses one explicit
window in the applied-zero travel coordinate. For example, an applied travel
zero of 30 mm and a manual 0--10 mm window fits the original 30--40 mm portion
of every loading or recovery branch that crosses it. A branch outside that
window, with fewer than eight selected points, or with zero selected travel
span is reported as **Insufficient fit region** and has no fitted line. Results
always retain the exact corrected-travel fit range, point count, stiffness,
modulus, R², and review status. Automatic mode still selects a branch-local
linear candidate but reports its endpoints in that same corrected coordinate.

The **Modulus Analysis** workspace shows stress-strain curves and fitted lines
beside summary statistics, with the full per-branch table below. Green solid
fits meet the R² criterion; orange dashed fits require review. Summary
statistics prefer accepted fits and fall back to all finite estimates when
none meet the threshold. **Export Modulus CSV** writes every row, including
review flags and the applied force/travel zero levels, rather than hiding
rejected or unusual cycles. The analysis
renderer rebuilds from the current result on every presentation, so prior fits
cannot accumulate. Fit endpoints and legend identities are ordinary plot
objects and remain present when the axes is popped into a MATLAB figure.

This App intentionally has no project schema: connections, samples, playback,
and visible state are transient. Closing the App does not prompt to save every
live refresh. Export is the explicit durable-data action.

**Tools > Developer Tools > Generate Synthetic Inputs...** writes anonymous
CSV, LOG, and MAT replay examples for training and visual inspection. It does
not emulate a serial device or alter the current session.

## Programmatic Driver

Use `labkit.mark10.connect`, `readSample`, `readSettings`, `writeSetting`,
`zeroForce`, `zeroTravel`, and `disconnect` for GUI-free workflows. See the
[Mark-10 driver manual](../../../libraries/mark10/README.md).

## Limitations

- Real serial-port exclusivity, cabling, fixture safety, and zero load must be
  checked by the operator.
- Identity and stand-status commands can be mode-dependent; readable force or
  travel remains the primary connection evidence.
- Reported modulus is an engineering estimate for a rectangular section. It
  does not correct grip compliance, machine compliance, changing area,
  extensometer offset, viscoelastic rate effects, or specimen slip. Review
  branch segmentation and the fitted region before reporting material data.
- Hidden-GUI tests do not validate physical hardware behavior or subjective
  plot quality.
