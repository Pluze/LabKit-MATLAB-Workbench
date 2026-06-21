# Documentation

Use this directory by task. Most work should need one or two pages, not the
whole documentation set.

## I Want To Use An App

Start with [apps.md](apps.md).

It explains how apps are launched, what each app is for, expected inputs, and
typical outputs.

## I Want To Create Or Modify An App

Read [apps.md](apps.md). Read [ui.md](ui.md) only when the work touches layout,
controls, previews, callbacks, or debug traces.

Use `labkit_ProjectGovernance_app` to create a starter app scaffold. After
generation, the result is ordinary MATLAB code under `apps/<family>/<slug>/`.

## I Want To Understand The Codebase

Read [architecture.md](architecture.md).

It explains the app-first model, when code belongs in an app-owned package, and
when a helper is reusable enough for `+labkit`.

## I Need To Validate A Change

Read [testing.md](testing.md).

It explains the supported build tasks, test layout, fixture expectations, and
what automated GUI checks do and do not prove.

For normal contributor work, start with the changed-file task. Use the full
non-GUI task when changed-file discovery is not available.

## I Am Using A Reusable Facade

| Facade | Read |
| --- | --- |
| GUI app shell, specs, view helpers, tools, diagnostics | [ui.md](ui.md) |
| Gamry DTA loading, sessions, parser outputs, pulse detection | [dta.md](dta.md) |
| Wearable/physiological recordings, ECG peaks, segments, measurements | [biosignal.md](biosignal.md) |
| Intan RHS discovery, header inspection, indexing, and window reads | [rhs.md](rhs.md) |

## What Is Not Here

Agent execution rules, migration ledgers, and skill procedures are intentionally
outside this human documentation set.
