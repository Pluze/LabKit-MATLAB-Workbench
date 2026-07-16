# VT Resistance

VT Resistance estimates cathodic and anodic steady resistance from pulse
voltage-transient recordings.

## Launch

```matlab
labkit_VTResistance_app
```

## Inputs And Performance

Load chrono DTA files. As in CIC, the app decodes the active file on demand and
defers the rest of a large batch until selection or export.

## Workflow

1. Add files and inspect pulse detection.
2. Choose the steady-window, voltage, and pulse-detection modes.
3. Review steady current, steady voltage, baseline, delta voltage, and
   cathodic/anodic resistance.
4. Export the complete batch with shared options.

## Scientific Semantics

The calculation takes medians over selected steady pulse windows. Raw mode
uses steady voltage divided by steady current. Delta-voltage mode subtracts a
pre/post baseline before division. The reported average resistance is the mean
of the absolute cathodic and anodic results.

Near-zero current, insufficient steady samples, or missing T/Vf/Im data cannot
produce a valid resistance and return a failure message.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("transient.DTA", "chrono");
assert(status.ok, status.message);
opts = struct("windowMode", "Middle 50%", ...
    "voltageMode", "Delta V", "pulseMode", "Auto");
result = vt_resistance.analysisRun.computeResistance(item, opts);
assert(result.ok, result.message);
```

Use `vt_resistance.userInterface.analysisChoices` rather than hard-coding
labels when building an automated workflow.

## See Also

- `vt_resistance.analysisRun.computeResistance`
- `labkit.dta.detectPulses`
- [CIC](../cic/README.md)
