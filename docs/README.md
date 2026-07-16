# LabKit Documentation

LabKit documentation is organized by the question you are trying to answer.
Start with a task guide, then open an API reference only when you need exact
MATLAB call syntax or returned data shapes.

## Choose A Starting Point

| I want to | Start here |
| --- | --- |
| Install, update, or open LabKit | [Getting started](getting-started/README.md) |
| Choose an app and understand its inputs and outputs | [App guide](apps/README.md) |
| Call a reusable `labkit.*` function | [Public API reference](libraries/README.md) |
| Understand ownership and package boundaries | [Architecture](development/architecture.md) |
| Create or modify an app | [App development](development/app-development.md) |
| Run tests or diagnose performance | [Testing](development/testing.md) |
| Understand documentation sources and generated HTML | [Documentation system](development/documentation.md) |
| Maintain a private app workspace | [Private apps](development/private-apps.md) |
| Prepare a release | [Release process](development/release.md) |

## Documentation Layers

```text
getting-started/  installation, launcher, updates, and first-run concepts
apps/             one directory per family and one subdirectory per app
framework/        UI runtime concepts, behavior, and app-authoring contracts
libraries/        one directory per reusable public MATLAB facade
how-to/           focused task recipes and documentation asset workflows
development/      architecture, app authoring, testing, private apps, release
history/          chronological change records and the project history index
catalogs/         structured app and app-owned API membership metadata
site.json         navigation, page identity, source, and output mapping
```

The structure follows the same separation used by mature technical
documentation sets: a short product landing page, task-oriented guides,
examples close to the task, and a distinct function reference. It deliberately
does not mirror the source tree one file at a time.

## Reference Conventions

Public function pages follow the MATLAB reference pattern:

1. summary and syntax
2. description and behavior
3. input arguments and options
4. output arguments and data shapes
5. algorithms or scientific semantics where relevant
6. errors and limitations
7. executable examples
8. version history, See Also, and related topics

Each app family has a landing page. Each concrete app owns a directory whose
`README.md` is its Get Started and detailed behavior page; complex apps can add
focused workflow, file-format, or algorithm topics beside it. App pages explain
launch, task flow, interaction rules, inputs, outputs, persistence, scientific
meaning, non-GUI APIs, errors, limitations, examples, related topics, and
component history as applicable. They do not document internal callbacks.

Framework and library landing pages follow the Qt module pattern: overview and
ownership first, followed by grouped concepts, supported public members,
detailed behavior, examples, and related modules. Generated function pages are
owned by MATLAB source help blocks. Handwritten HTML is never a source.

## Project History And Support

- [Project history](history/README.md) lists all change records and connects
  them to the affected apps, framework, and libraries.
- [Support](../.github/SUPPORT.md) explains how to report workflow problems.
- [Documentation asset guide](how-to/workflow-assets.md) explains how to
  generate synthetic screenshots and example outputs.

Agent execution rules, skills, and active migration debt stay outside this
human documentation set in scoped `AGENTS.md` files and `.agents/`.
