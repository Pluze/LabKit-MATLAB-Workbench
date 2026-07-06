# Documentation

Use this directory by task. Normal app users should only need the launcher and
the app catalog; maintainer references are grouped separately.

## App Users

- [Root README](../README.md): download the single-file launcher and start
  LabKit.
- [apps.md](apps.md): see available apps, expected inputs, and typical
  outputs.

## App Authors And Maintainers

- [apps.md](apps.md): app file shape, app ownership, and new-app guidance.
- [private-apps.md](private-apps.md): local private app workspace structure
  for apps kept outside the public repository.
- [architecture.md](architecture.md): package boundaries and extraction rules.
- [testing.md](testing.md): compact build-task entry points, automatic
  changed-file routing, CI scope, fixtures, and GUI validation limits.
- [release.md](release.md): version selection, tag naming, and GitHub release
  note format.
- [Component changelog](../CHANGELOG.md): current component versions and
  user-facing launcher, facade, app, and release-tag version history.
- [workflow-assets.md](workflow-assets.md): command-line generation of real app
  screenshots and example outputs for SOPs and onboarding guides.

## Reusable Facades

| Facade | Read |
| --- | --- |
| GUI app shell, specs, view helpers, tools, diagnostics | [ui.md](ui.md) |
| Image file IO, preview normalization, and basic processing primitives | [image.md](image.md) |
| Thermal source parsing, raw-to-temperature conversion, and thermal rendering | [thermal.md](thermal.md) |
| Gamry DTA loading, parser outputs, pulse detection | [dta.md](dta.md) |
| Wearable/physiological recordings, ECG peaks, segments, measurements | [biosignal.md](biosignal.md) |
| Intan RHS discovery, header inspection, indexing, and window reads | [rhs.md](rhs.md) |

## Not In Human Docs

Agent execution rules, migration ledgers, and skill procedures are intentionally
outside this human documentation set.
