# LabKit Documentation

LabKit documentation is organized by the question you are trying to answer.
Start with a task guide, then open an API reference only when you need exact
MATLAB call syntax or returned data shapes.

## Choose A Starting Point

| I want to | Start here |
| --- | --- |
| Install, update, or open LabKit | [Getting started](getting-started/README.md) |
| Choose an app and understand its inputs and outputs | [App guide](apps/README.md) |
| Call a reusable `labkit.*` function | [Public API reference](api/README.md) |
| Understand ownership and package boundaries | [Architecture](development/architecture.md) |
| Create or modify an app | [App development](development/app-development.md) |
| Run tests or diagnose performance | [Testing](development/testing.md) |
| Understand documentation sources and generated HTML | [Documentation system](development/documentation.md) |
| Maintain a private app workspace | [Private apps](development/private-apps.md) |
| Prepare a release | [Release process](development/release.md) |

## Documentation Layers

```text
getting-started/  installation, launcher, updates, and first-run concepts
apps/             task-oriented app catalog and workflow behavior
api/              supported public MATLAB functions grouped by facade
development/      architecture, app authoring, testing, private apps, release
guides/           focused maintainer recipes and generated documentation assets
```

The structure follows the same separation used by mature technical
documentation sets: a short product landing page, task-oriented guides,
examples close to the task, and a distinct function reference. It deliberately
does not mirror the source tree one file at a time.

## Reference Conventions

Public API pages use a consistent order:

1. purpose and ownership boundary
2. common calls or syntax
3. inputs, options, outputs, and data shapes
4. examples and related functions

App pages describe user workflows rather than internal callbacks. Development
pages describe current contracts rather than migration history.

## Project History And Support

- [Component changelog](../CHANGELOG.md) records current versions and
  structured evolution.
- [Support](../.github/SUPPORT.md) explains how to report workflow problems.
- [Documentation asset guide](guides/workflow-assets.md) explains how to
  generate synthetic screenshots and example outputs.

Agent execution rules, skills, and active migration debt stay outside this
human documentation set in scoped `AGENTS.md` files and `.agents/`.
