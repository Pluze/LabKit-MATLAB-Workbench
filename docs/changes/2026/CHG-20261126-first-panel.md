# Make task panels ready on the first visit

```labkit-change
id: CHG-20261126-first-panel
date: 2026-11-26
type: fix
compatibility: compatible
component: labkit.app | 3.7.3 -> 3.7.4
```

## Why

Opening a task page for the first time could pause while MATLAB built its drag handles and searched for text to resize. Moving handles between pages also slowed later visits.

## What changed

Each page has its drag surfaces when the window opens. Section headings and controls share a grid, and the workbench keeps track of the readouts that need to wrap when a page changes width.

## Impact

Operators can switch tasks and immediately resize a section. Returning to a page preserves the height of its sections.

## Compatibility and limits

Existing App definitions and saved files work as before. First-visit latency still depends on the controls and plots MATLAB needs to display.
