# EIS overview uses linear magnitude and a shared view reset

```labkit-change
id: CHG-20260922-eis-overview-axes
date: 2026-09-22
type: fix
compatibility: compatible
component: labkit_EIS_app | 1.8.1 -> 1.8.2
```

## Why

The overview's logarithmic magnitude axis made some impedance curves harder to compare by absolute difference. After zooming, restoring all three overview ranges required changing the source or unit.

## What changed

- The overview magnitude plot now uses a linear Y axis. Both Bode frequency X axes remain logarithmic.
- **Fit all X/Y limits** restores the data-fitted Nyquist, magnitude, and phase ranges together, including equal data units on Nyquist.

## Impact

The first page has a different default magnitude view and a manual reset control. Custom plot settings, source data, calculations, and CSV exports are unchanged.

## Compatibility and limits

Existing projects load with the new overview default. The reset is a transient view action and is not saved in a project.
