# Support singleton dimensions in image interpolation

```labkit-change
id: CHG-20260906-focus-stack-singleton
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_FocusStack_app | 1.9.0 -> 1.9.1
component: labkit.image | 2.0.4 -> 2.0.5
```

## Why

Small supported images could produce a singleton pyramid dimension that bilinear interpolation could not expand. The public resizeToFit API had the same limitation when enlarging a row, column, or single pixel.

## What changed

App-local pyramid resizing and public resizeToFit repeat the constant singleton axis while preserving interpolation on the other axis. The manual describes small-image limitations and the actual in-memory workflow.

## Impact

One-row, one-column, and one-pixel inputs can complete without an interpolation-grid error. Ordinary image geometry and focus-fusion rules are unchanged.

## Compatibility and limits

A singleton axis provides no spatial focus information in that direction. The App does not create or restore a saved stack archive.
