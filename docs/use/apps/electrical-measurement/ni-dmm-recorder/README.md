# NI-DMM Recorder

```labkit-page
id: app-ni-dmm-recorder
type: landing
audience: app-user
summary: Record NI-DMM voltage, current, two-wire or four-wire resistance, and diode readings with UTC timing metadata.
```

NI-DMM Recorder is a public LabKit App for NI digital multimeters including the USB-4065. It records the complete in-memory run, plots a bounded recent view, and exports data suitable for host-clock alignment with Mark-10 Monitor.

## Prepare And Connect

Install the 64-bit NI-DMM driver with .NET and NI System Configuration support, then confirm the device appears in NI MAX. LabKit never downloads or installs these dependencies. Run `labkit_NIDMMRecorder_app`; it automatically discovers local NI-DMM devices and selects the first result. Choose another device from **NI-DMM device** when several are present, or use **Refresh Devices** after changing the USB connection. Operators do not need to enter or know a NI MAX resource name. Missing software and empty discovery results are reported without crashing the App.

Select DC/AC voltage, DC/AC current, two-wire resistance, four-wire resistance, or diode. Choose a fixed full-scale range or **Automatic**. Automatic performs one settling reading and locks the hardware-selected range for the run. Choose 4.5, 5.5, or 6.5 digits and a requested rate from 10 through 50 Hz. The default is 30 Hz; 50 Hz is optional, not an acceptance requirement. When the applied mode and resolution require a longer measurement period, the App uses the fastest achievable target instead and reports both the requested and device-limited target rates.

Confirm leads and mode before **Read Once** or **Start Recording**. Starting replaces the preceding in-memory run. **Stop Recording** ends hardware acquisition, restores immediate trigger state, and keeps the DMM connected so another read or recording can start without reconnecting. The status shows actual retained rate rather than assuming the requested rate.

The live reading, recent plot, and recent-data table choose one readable engineering unit from the current reading and displayed sample window. Supported voltage, current, and resistance readings may appear with n, u, m, k, M, or G prefixes; zero keeps the base unit. When that choice changes, the plot refits to the new scale. **Automatic** under Range selection controls the instrument's full-scale range independently of this display formatting.

## Export And Synchronize

**Export CSV + MAT** writes valid readings to CSV and the complete attempt history plus applied configuration to MAT. CSV columns are `TimestampUTC`, `Elapsed_s`, `Measurement`, `Unit`, `Mode`, and `TimeUncertainty_s`. MAT also retains host receipt times, validity, requested rate, device-limited target rate, and recording start time.

Exports retain the unscaled device readings and their base unit (`V`, `A`, or `ohm`) regardless of the unit shown in the App.

Mark-10 Monitor exports the same host UTC concept. Start both recordings near the same time, retain their independent UTC columns, and align later by `TimestampUTC`; include `TimeUncertainty_s` when judging event correspondence. This is clock-based synchronization, not a common hardware trigger. A sharp physical event visible to both instruments can improve post-processing alignment.

Both Apps may run in one MATLAB instance. NI buffered acquisition uses its device engine plus a Base MATLAB timer, while Mark-10 owns the available Base MATLAB background worker. If stronger fault isolation is needed, manually open two MATLAB instances from different LabKit launchers and give each process a different device. Do not connect the same device twice.

## Limitations

- NI USB-4065 support requires 64-bit Windows plus end-user-installed NI-DMM and NI System Configuration .NET support.
- One process owns a physical NI-DMM or serial port at a time.
- UTC timestamps are host estimates; neither device shares a LabKit-controlled sample clock or trigger.
- Wiring safety, current terminals, voltage limits, and two-wire versus four-wire lead placement remain operator responsibilities.
- Hidden-GUI tests do not replace real-device and real-fixture validation.

For programmatic acquisition and exact error contracts, see the [NI-DMM facade manual](../../../../develop/libraries/nidmm/README.md).
