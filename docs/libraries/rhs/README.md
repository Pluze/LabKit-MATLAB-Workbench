# Intan RHS Recordings

[API reference](../README.md) | [Neurophysiology apps](../../apps/neurophysiology/README.md)

The `labkit.rhs` functions inspect Intan RHS recordings and read selected
waveform windows without loading an entire file into memory. They expose file
metadata, channel names, data-block layout, timestamps, and samples in
physical units. The functions can be called directly from MATLAB without
opening a LabKit app.

## Start Here

Inspect a file first when you need to see its channels and duration:

```matlab
[info, status] = labkit.rhs.inspectFile("recording.rhs");

if ~status.ok
    error("Could not inspect RHS file: %s", status.message)
end

fprintf("%.2f s at %.0f Hz\n", info.durationSec, info.sampleRateHz)
disp(info.channelTable(:, ["family", "nativeName", "customName"]))
```

Then read only the channels and times required by the analysis:

```matlab
opts = struct( ...
    "family", "amplifier", ...
    "channels", ["C-001", "C-002"], ...
    "timeRangeSec", [0.100 0.150]);

[window, status] = labkit.rhs.readWindow("recording.rhs", opts);
if status.ok
    plot(window.timeSec, window.values)
    xlabel("Time (s)")
    ylabel("Amplitude (microvolts)")
    legend(window.channels)
end
```

`window.values` is always samples-by-channels. `window.timeSec` contains the
timestamps stored in the recording, converted to seconds.

## Choose a Function

| Task | Function |
| --- | --- |
| Find RHS paths recursively | [`labkit.rhs.findFiles`](../../reference/api/labkit/rhs/findFiles.html) |
| Read header, channel, and duration information | [`labkit.rhs.inspectFile`](../../reference/api/labkit/rhs/inspectFile.html) |
| Build the byte/sample layout for later reads | [`labkit.rhs.indexFile`](../../reference/api/labkit/rhs/indexFile.html) |
| Read one channel family and time interval | [`labkit.rhs.readWindow`](../../reference/api/labkit/rhs/readWindow.html) |
| Check library version and compatibility | [`labkit.rhs.version`](../../reference/api/labkit/rhs/version.html) |

## Header Information

`inspectFile` reads the header and calculates how much complete waveform data
is available. Important fields include:

| Field | Meaning |
| --- | --- |
| `fileVersion` | Intan file-format major and minor version |
| `sampleRateHz` | Amplifier sample rate in hertz |
| `durationSec` | Duration represented by complete data blocks |
| `channelFamilies` | Channel structures grouped as amplifier, board ADC, board DAC, digital input, and digital output |
| `channelTable` | One table combining enabled stored channels and their native/custom names |
| `frequencyParameters` | Requested and actual filter and bandwidth settings |
| `stimParameters` | Stimulation step size and charge-recovery settings |
| `dcAmplifierSaved` | Whether DC-amplifier samples are stored |
| `blockCount`, `sampleCount` | Number of complete blocks and samples |
| `exactBlocks` | Whether the data section ends on a complete block boundary |

Header-only files can be inspected successfully and have a sample count of
zero. A file with trailing partial bytes remains readable through its last
complete block; `exactBlocks` is false and the status message reports the
condition.

## Channel Families and Units

`readWindow` reads one family at a time:

| Family | Accepted examples | Returned unit |
| --- | --- | --- |
| `"amplifier"` | `"amplifier"`, `"amp"` | microvolts |
| `"stim"` | `"stim"`, `"stimulus"`, `"stimcurrent"` | microamps |
| `"dcAmplifier"` | `"dc"`, `"dcamplifier"`, `"dcamp"` | volts |
| `"boardAdc"` | `"boardadc"`, `"adc"` | volts |
| `"boardDac"` | `"boarddac"`, `"dac"` | volts |
| `"boardDigIn"` | `"boarddigin"`, `"digitalin"`, `"digin"` | logical 0 or 1 |
| `"boardDigOut"` | `"boarddigout"`, `"digitalout"`, `"digout"` | logical 0 or 1 |

Family matching ignores case and punctuation. Selecting a family that has no
stored channels returns `status.ok=false` with an empty window.

### Selecting Channels

Set `channels=[]` to read every channel in the selected family. Otherwise use
one-based numeric positions, native names, or custom names:

```matlab
opts.channels = [1 3];
opts.channels = ["C-001", "C-003"];
opts.channels = ["Reference", "Recording"];
```

Names are matched exactly first. If no exact match is found, comparison ignores
case and punctuation, so `"C001"` can match the native name `"C-001"`.
Returned `window.channels` always contains native channel names.

## Selecting a Time Window

`timeRangeSec=[start end]` selects an inclusive sample interval. The start is
clamped to zero, `Inf` reads through the last complete sample, and an end past
the recording duration is clipped. For example:

```matlab
opts.timeRangeSec = [0 0.050];       % first 50 ms
opts.timeRangeSec = [1.5 Inf];       % from 1.5 s to the end
```

A valid request that begins after the available data returns `status.ok=true`
with empty `timeSec` and `values`, allowing a caller to distinguish an empty
interval from a file-read failure.

## Block Indexing and Lazy Reads

RHS waveform data is stored in 128-sample blocks. `indexFile` calculates the
header offset, bytes per block, complete block count, sample count, and
duration without reading the waveform arrays. `readWindow` uses this index to
seek directly to the blocks that overlap the requested interval.

```matlab
[index, status] = labkit.rhs.indexFile("recording.rhs");
if status.ok
    fprintf("%d samples in %d blocks\n", ...
        index.sampleCount, index.blockCount)
end
```

This makes short previews and event-centered analyses practical for recordings
that are too large to load all at once.

## Physical-Unit Conversion

The reader follows the Intan RHS block layout and applies the documented
conversion gains and code offsets for amplifier, DC-amplifier, stimulation,
board ADC, and board DAC data. Digital inputs and outputs are decoded from
their stored bit positions. No filtering, baseline correction, event
detection, channel-role interpretation, or response measurement is performed
by these file-reading functions.

## Errors and Unsupported Files

Missing files, malformed headers, unsupported magic numbers, absent channel
families, and waveform read failures are returned through `status.ok=false`
and `status.message`. Invalid function arguments, such as an unknown family,
channel, or reversed time range, throw the documented `labkit:rhs:*` error.

Successful parsing confirms that the supported RHS header and complete block
layout were readable. It does not validate an experiment protocol, decide
which channels form a differential signal, or assess recording quality.

## Related Topics

- [RHS Preview](../../apps/neurophysiology/rhs-preview/README.md) provides
  interactive waveform review and channel-role drafting.
- [Nerve Response Analysis](../../apps/neurophysiology/nerve-response-analysis/README.md)
  reads selected RHS channels for event and response calculations.
- [Biosignal functions](../biosignal/README.md) operate on imported recordings
  and generic waveforms after file IO.
- [Project history](../../history/README.md) lists RHS parser and app changes.
