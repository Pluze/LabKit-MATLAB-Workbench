# Documentation Guide

These docs are written for people who run, maintain, or extend LabKit. Start with the page that matches the work in front of you; you do not need to read the whole documentation set for everyday app use.

## I Want To Run An App

- `../README.md`: project overview, startup command, app list, and basic test commands.
- `apps.md`: current app families, what each app does, expected inputs, and typical outputs.

## I Maintain An App

- `apps.md`: app ownership, current app notes, new-app checklist, and validation guidance.
- `ui.md`: shared GUI shell, tabs, panels, axes, and reusable UI helper contracts.
- `testing.md`: focused app and GUI structural build-task commands.

## I Work On Reusable APIs

- `architecture.md`: package boundaries and the extraction rule for moving code into `+labkit`.
- `ui.md`: reusable GUI foundation.
- `dta.md`: Gamry DTA loading, parsing, session, pulse, and curve facade.
- `biosignal.md`: recording loading, signal processing, ECG detection, segments, templates, and measurements.

## I Need Validation Guidance

- `testing.md`: default and focused build tasks, GUI versus non-GUI checks, fixture expectations, and CI scope.

## Component Reference

| Doc | Use it for |
| --- | --- |
| `architecture.md` | Package boundaries, ownership rules, and extraction decisions. |
| `apps.md` | App entry points, app-family notes, and app-owned workflow guidance. |
| `ui.md` | MATLAB GUI shell and reusable UI helpers. |
| `dta.md` | DTA facade, parser assumptions, and data shapes. |
| `biosignal.md` | Biosignal facade, data shapes, and ECG workflow boundary. |
| `testing.md` | Test commands, suite layout, GUI validation limits, and fixture expectations. |
