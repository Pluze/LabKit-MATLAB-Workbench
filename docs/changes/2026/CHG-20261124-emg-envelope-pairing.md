# Pair EMG activity with its preceding baseline

```labkit-change
id: CHG-20261124-emg-envelope-pairing
date: 2026-11-24
type: fix
compatibility: compatible
component: labkit_EMGReview_app | 1.0.0 -> 1.0.1
```

## Why

Independent extrema over a recording could pair a contraction with a much later baseline or repeatedly mark the same contraction.

## What changed

Automatic marking segments a short-time RMS envelope into quiet and sustained activity intervals. It chooses one window per contraction and finds the matching baseline in the preceding quiet interval.

## Impact

Pairs follow recording order. Unmarked rows stay off the waveform, and the App asks for manual selection when there is no distinct pair.

## Compatibility and limits

The measurement and export formulas still use the selected waveform samples. Envelope contrast identifies candidates for review and can also reflect sustained artifacts.
