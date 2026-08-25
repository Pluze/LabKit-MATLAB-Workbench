# LabKit Documentation

```labkit-page
id: home
type: landing
audience: new-user
summary: Choose the shortest LabKit documentation path for installation, App use, development, exact reference, maintenance, upgrades, or past changes.
```

LabKit documentation is organized by the question you are trying to answer. Start with a task guide, then open an API reference only when you need exact MATLAB call syntax or returned data shapes.

## Choose A Starting Point

| I want to | Start here |
| --- | --- |
| Install, update, or open LabKit | [Getting started](start/README.md) |
| Understand every launcher action or call it from MATLAB | [LabKit Launcher](apps/labkit-core/launcher/README.md) |
| Choose an app and understand its inputs and outputs | [App guide](apps/README.md) |
| Call a reusable `labkit.*` function | [Public API reference](reference/README.md) |
| Understand ownership and package boundaries | [Architecture](develop/app-authoring/architecture.md) |
| Create or modify an app | [App development](develop/app-authoring/app-development.md) |
| Run tests or diagnose performance | [Testing](maintain/testing.md) |
| Call packaging, profiling, codecheck, or documentation tools | [Maintainer tools](maintain/tools/README.md) |
| Understand documentation sources and generated HTML | [Documentation system](maintain/documentation.md) |
| Maintain a private app workspace | [Private apps](maintain/private-apps.md) |
| Prepare a release | [Release process](maintain/release.md) |
| Understand why a change happened or an earlier choice was replaced | [Changes](changes/README.md) |
| Review a published version before upgrading | [GitHub Releases](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases) |

## Documentation Layers

```text
start/            installation, launcher, updates, and first-result tasks
apps/             product overviews, tasks, concepts, and troubleshooting
develop/          App authoring, framework, and reusable library guidance
maintain/         contribution, testing, documentation, and release tasks
reference/        exact functions, schemas, terms, errors, and compatibility
upgrade/          supported upgrade actions and compatibility boundaries
changes/          why accepted changes happened and what they changed
```

Each current Markdown page declares its reader, type, summary, and stable semantic ID. Typed Change records imply their own authority. Each path owns its route. Public App manuals are matched to `labkit_launcher("list")`; App-owned function pages are discovered from complete public MATLAB help contracts.

## Reference Conventions

Public function pages follow the MATLAB reference pattern:

1. summary and syntax
2. description and behavior
3. input arguments and options
4. output arguments and data shapes
5. algorithms or scientific semantics where relevant
6. errors and limitations
7. executable examples
8. related changes, See Also, and related topics

Each app family has a landing page. Each concrete app owns a directory whose `README.md` is its Get Started and detailed behavior page; complex apps can add focused workflow, file-format, or algorithm topics beside it. App pages explain launch, task flow, interaction rules, inputs, outputs, persistence, scientific meaning, non-GUI APIs, errors, limitations, examples, related topics, and related changes as applicable. They do not document internal callbacks.

Framework and library landing pages follow the Qt module pattern: overview and ownership first, followed by grouped concepts, supported public members, detailed behavior, examples, and related modules. Generated function pages are owned by MATLAB source help blocks. Handwritten HTML is never a source.

## Changes, Releases, And Support

- [Changes](changes/README.md) preserve why accepted changes happened, their effects, compatibility, and supersession chains.
- [GitHub Releases](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases) are the single source for published version summaries and exact tags.
- [Support](../.github/SUPPORT.md) explains how to report workflow problems.
