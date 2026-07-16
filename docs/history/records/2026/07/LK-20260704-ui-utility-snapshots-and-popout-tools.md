# UI utility snapshots and popout tools

```labkit-change
schema: 1
id: LK-20260704-ui-utility-snapshots-and-popout-tools
date: 2026-07-04
type: feat
compatibility: compatible
component: `labkit.ui` | `4.1.0 -> 4.2.0`
```

## Context

Users could tune controls and plots during a session, but restoring that work
required repeating the settings manually. Popout axes were useful for visual
inspection, yet copying data or recreating the plot in a script still required
ad hoc commands.

## Decision and rationale

Give the runtime a serializable snapshot contract for app state and expose save
and load as workbench utilities. Extend popout axes with explicit styling,
image copy, data export, and reconstruction-script actions derived from the
graphics objects already present on the axes.

## Changes

- `labkit.ui` `4.1.0 -> 4.2.0`

- Added UI state snapshot save/load APIs.
- Added workbench utility controls.
- Improved axes popout export and copy tools.

## User and data impact

Users could save a supported app state and restore it later from the workbench.
Popout plots could be restyled, copied, exported as visible graphics data, or
used to generate a MATLAB reconstruction script without changing the original
app result.

## Compatibility and migration

Apps that did not declare serializable state continued to run without snapshot
support. Existing app data and figure files were not converted automatically.

## Validation

The commit expanded app-runtime and axes-workbench GUI suites and added package-
surface checks for the snapshot APIs. The exact historical command was not
recorded.

## Evidence

- Main commit `0155cd12`.

## Known limitations and follow-up

Snapshots covered state declared serializable by the app; they were not raw
MATLAB workspace dumps. Figure Studio later provided a dedicated workflow for
more extensive figure cleanup and export.
