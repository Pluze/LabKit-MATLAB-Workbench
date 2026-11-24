# Import BIOPAC ACQ waveforms directly

```labkit-change
id: CHG-20261123-acq-waveform-import
date: 2026-11-23
type: feat
compatibility: compatible
component: labkit.biosignal | 3.0.2 -> 3.1.0
component: labkit_ECGPrint_app | 4.0.0 -> 4.1.0
```

## Why

A BIOPAC recording often starts as an ACQ file. Requiring a MAT or text export adds a conversion step before a recording can be reviewed.

## What changed

The biosignal reader decodes the interleaved ACQ waveform and applies integer channel calibration. ECG Print offers ACQ in its recording picker and uses the file's embedded clock.

## Impact

Users can open supported recordings directly and select channels by their recorded labels.

## Compatibility and limits

Direct import handles uncompressed big-endian revision 133 with equal-length channels and sample divider 1. It reads waveform channels and their labels and units. Event annotations and trailing configuration remain outside waveform import.
