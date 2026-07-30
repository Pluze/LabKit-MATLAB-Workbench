# Source-built documentation delivery and bounded CI sharding

```labkit-change
id: LK-20260730-source-built-documentation-delivery
date: 2026-07-30
sequence: 163
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.7.1 -> 1.8.0`
scope: Online-first Launcher documentation with optional local generation
scope: GitHub Pages generated from Markdown and MATLAB help on main
scope: Selective MATLAB CI sharding without duplicate post-merge validation
```

## Context

The repository tracked hundreds of generated `site/` files even though
Markdown and public MATLAB help were the authored sources. Documentation edits
therefore required local regeneration and large mechanical diffs, while the
Pages workflow merely uploaded whatever generated tree happened to be
committed. The expanded MATLAB compatibility matrix also serialized three
independent sessions per platform and then repeated the complete matrix after
the validated pull request was squash-merged.

## Decision and rationale

Treat generated documentation as a build artifact. GitHub Pages now generates
the site from the exact `main` source, while local generation remains an
ignored convenience for offline reading. The Launcher opens online
documentation by default and offers a bounded local-generation choice only
when a user explicitly requests local documentation.

Use measured critical-path sharding rather than a complete profile Cartesian
product. Only latest Windows and macOS split hidden GUI from headless plus path
isolation; shorter platform jobs continue to reuse one MATLAB setup. Required
strict PR checks own the complete matrix, and the protected main push retains
only the exact-commit policy record needed by release automation.

## Changes

- Removed generated `site/` output from Git tracking and ignored local renders.
- Made the Documentation Pages workflow install MATLAB, render the exact main
  source, upload the Pages artifact, and deploy it without branch writes.
- Changed `docsCheck` to compare two independent temporary renders by default.
- Changed Launcher documentation lookup to return GitHub Pages URLs by
  default and added an explicit `"local"` source for programmatic callers.
- Replaced **Update Documentation** with **Local Documentation**. A missing
  local page offers **Open Online** by default, **Generate Local**, or
  **Cancel**.
- Split only the measured latest Windows and macOS CI critical paths and
  stopped rerunning the expensive matrix after protected squash merges.

## User and data impact

Documentation authors commit only Markdown, MATLAB help, and renderer changes.
Users receive current online documentation from GitHub Pages. Source-checkout
users can still generate and open `site/` locally; no project, input, result,
or scientific data format changes.

## Compatibility and migration

Existing `buildtool docs` and explicit
`checkLabKitDocs(sourceRoot, existingSiteRoot)` calls remain available.
Programmatic Launcher documentation calls now return the online URL unless
`"local"` is requested. Scripts that require a filesystem path must add that
explicit source and generate the ignored local site first.

## Validation

Repository-owned Python summary and policy tests cover scheduled-profile
shards. MATLAB launcher specifications cover online routing, explicit local
routing, missing-local behavior, generation choice, and tool adaptation.
Repository architecture specifications cover Pages generation, ignored site
ownership, CI shard shape, and protected integration routing. `docsCheck`
proves deterministic complete generation from authored sources.

## Evidence

The CI workflow, Pages workflow, launcher dispatch specifications,
documentation renderer check, build tasks, authored manuals, and this history
record are the reviewable evidence. Pull-request Actions artifacts retain each
scheduled MATLAB shard's JUnit, log, active-test, and visual-evidence outputs.

## Known limitations and follow-up

Automated hidden-GUI tests do not prove the external browser experience or the
native confirmation dialog's visual quality. GitHub Pages deployment still
depends on GitHub and MathWorks Actions availability; ignored local
documentation remains the offline fallback.
