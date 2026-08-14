# Mark-10 Force/Travel Monitor

Mark-10 Monitor connects to an ESM303 with an attached Series 5 gauge,
displays live force and travel, records without controlling stand motion, and
replays previously exported data.

The central workspace follows the official monitoring workflow with separate
**Live Plots** and **Recent Data** pages. The table shows the latest 200 valid
visible samples while the full recording remains in the managed buffer.

## Connect And Record

Run `labkit_Mark10Monitor_app`, choose **Refresh Ports**, select the serial
port, and choose **Connect**. Monitoring begins immediately. **Start
Recording** clears the retained recording and starts capture; **Stop
Recording** leaves the live monitor running.

Choose 5, 10, or 20 Hz for paced acquisition. **Maximum** requests samples as
quickly as the device and MATLAB event loop permit; measured rate is shown
instead of assuming the requested value. The App uses synchronized `n` reads
when possible and reports fallback `x + ?C` acquisition in diagnostics.

**Zero Force** verifies the Series 5 zero against its displayed resolution.
**Zero Travel** uses hardware zero only when stand status proves that command
path is available; otherwise it applies a visible and exported software-zero
offset. The App never sends UP, DOWN, motion speed, limit, cycle, or automatic
`SAVE` commands.

## Gauge Settings

The settings tab reads and verifies Series 5 unit, measurement mode, current
and display filters, output format, and Auto Output. **Apply + Verify** checks
each change with `LIST`. It does not persist settings with `SAVE`. Auto Output
is held at zero during synchronous monitoring and restored on disconnect.

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

## Open And Replay

Disconnect hardware, choose **Open Recording**, and select an App CSV, MESUR
gauge LOG, or complete MAT export. **Play** follows the recorded relative time;
**Pause** retains the current cursor. Replay uses the same bounded plot and
coalesced Runtime refresh path as live acquisition. Hardware connection is
disabled during replay and replay controls are disabled while connected.

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
- Hidden-GUI tests do not validate physical hardware behavior or subjective
  plot quality.
