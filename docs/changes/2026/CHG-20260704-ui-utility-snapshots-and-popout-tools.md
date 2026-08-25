# UI utility snapshots and popout tools

```labkit-change
id: CHG-20260704-ui-utility-snapshots-and-popout-tools
date: 2026-07-04
type: feat
compatibility: compatible
component: labkit.ui | 4.1.0 -> 4.2.0
```

## Why

Users could tune controls and plots during a session, but restoring that work required repeating the settings manually. Popout axes were useful for visual inspection, yet copying data or recreating the plot in a script still required ad hoc commands.

### Accepted choice

Give the runtime a serializable snapshot contract for app state and expose save and load as workbench utilities. Extend popout axes with explicit styling, image copy, data export, and reconstruction-script actions derived from the graphics objects already present on the axes.

## What changed

- Added UI state snapshot save/load APIs.
- Added workbench utility controls.
- Improved axes popout export and copy tools.

## Impact

Users could save a supported app state and restore it later from the workbench. Popout plots could be restyled, copied, exported as visible graphics data, or used to generate a MATLAB reconstruction script without changing the original app result.

## Compatibility and limits

Apps that did not declare serializable state continued to run without snapshot support. Existing app data and figure files were not converted automatically.

### Remaining limits

Snapshots covered state declared serializable by the app; they were not raw MATLAB workspace dumps. Figure Studio later provided a dedicated workflow for more extensive figure cleanup and export.
