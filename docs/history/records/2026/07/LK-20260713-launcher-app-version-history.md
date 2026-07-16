# Launcher app version history

```labkit-change
schema: 1
id: LK-20260713-launcher-app-version-history
date: 2026-07-13
type: feat
compatibility: additive
component: `labkit_launcher` | `1.3.0 -> 1.4.0`
```

## Context

The structured changelog could be parsed by maintainers, but launcher users
could not inspect the history of the selected app. Earlier normalization also
attached broad release descriptions without recording every app version event,
which made histories such as CIC appear to begin years of versions too late.

## Decision and rationale

Expose component-filtered history in the launcher and make exact component
events the durable lookup key. A user should be able to move from the current
app catalog directly to its evolution record without reading Git history or
understanding changelog internals.

## Changes

- Added `labkit_launcher("history", appCommand)` for programmatic history
  lookup and a Version History viewer for the selected launcher app.
- Added explicit component introduction events and reconstructed every tracked
  launcher, facade, and app version transition from `origin/main` history.
- Added continuous-history validation so missing introductions, gaps, and
  current-version mismatches fail the release guardrail.

## User and data impact

Launcher users can inspect dated version transitions, compatibility, rationale,
impact, and evidence for the selected app. App calculations and user data are
unchanged.

## Compatibility and migration

The launcher command and button are additive. Existing list, version, package,
maintenance, and app-launch workflows remain available.

## Validation

`LauncherGuiTest` covers programmatic filtering and the hidden GUI viewer;
`ChangelogGuardrailTest` validates complete version chains against current
metadata. These checks were included in the combined mainline change
`4a6c41dd`.

## Evidence

- Component history, launcher viewer, and changelog validation were included in
  `4a6c41dd`.
- Historical component events were reconstructed from version-file changes on
  the then-current `origin/main` history.

## Known limitations and follow-up

History begins when version metadata was first tracked for each component.
Behavior before that point can only be inferred from older source commits and
is not assigned invented version numbers.
