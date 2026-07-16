# Searchable MATLAB-generated documentation site and launcher workflow groups

```labkit-change
schema: 1
id: LK-20260715-documentation-site
date: 2026-07-15
type: feat
compatibility: additive
component: `labkit_launcher` | `1.4.0 -> 1.5.0`
scope: `docs/`
scope: `site/`
scope: `tools/docs/`
scope: `buildfile.m`
```

## Context

The documentation had become a set of large Markdown pages with no generated
site, global search, code-entity pages, or enforced relationship between the
public MATLAB surface and its reference material. Launcher actions were also
presented as a mostly flat list, making routine app launch, installation,
maintenance, profiling, and packaging appear equally related.

## Decision and rationale

Keep authoring in tracked Markdown, structured navigation/catalog metadata,
and MATLAB help blocks, then use one repository-owned MATLAB compiler to emit
the tracked static site. Bind every non-private `labkit.*` API and each
explicitly cataloged app-owned scientific API to its source declaration. Keep
private helpers out of detailed reference pages.

Group launcher actions by user intent and make documentation regeneration a
first-level maintenance action. This follows the separation used by MATLAB
and Qt documentation while keeping the build offline and dependency-free.

## Changes

- Added a MATLAB-only static documentation compiler, responsive site chrome,
  global client-side search, source links, related-API links, and deterministic
  generated-tree comparison.
- Added structured page and app-owned API catalogs. Generated reference now
  covers reusable library functions plus explicitly supported GUI-free app
  calculation entry points, while rejecting `private/` paths.
- Added public documentation build and consistency tasks and project
  guardrails for catalog coverage, search visibility, and generated output.
- Reorganized launcher buttons into Run Apps, Versions and Install,
  Development and Maintenance, and Package and Publish groups.
- Added Update Documentation to the launcher. It rebuilds `site/`, opens the
  generated home page, and reports narrative-page, API-page, file, and output
  location details.

## User and data impact

Users can browse and search documentation without a MATLAB documentation
server, move between related public functions, and regenerate the same site
after source changes. Existing app data, projects, calculations, and exports
are unchanged. Launcher maintenance actions are easier to distinguish from
normal app launch and installation tasks.

## Compatibility and migration

The feature is additive. Existing Markdown links remain valid in the source
repository. `site/` is generated and must not be edited manually. Source-only
or P-code app packages that omit documentation tools show the launcher action
disabled with an explanatory tooltip.

## Validation

The compiler generated 20 narrative pages, 133 public API pages, and 157
tracked files. Focused documentation/build guardrails passed after verifying a
byte-for-byte rebuild. Hidden-GUI launcher layout, documentation generation,
and missing-tool behavior tests passed 3/3.

## Evidence

- `tools/docs/renderLabKitDocs.m` and `docs/site.json` define the deterministic
  build and navigation contract.
- `docs/catalogs/api.json` defines the supported app-owned public API surface.
- Initial searchable site and launcher integration `bdeba572`.
- Per-app documentation publication `82734a47`.
- Later information-architecture rebuild `8b55e2b9`.

## Known limitations and follow-up

The first generated site still contains transitional narrative pages that
must be split into app-family, per-app, framework, and focused API guides.
Cataloged scientific APIs need richer standalone examples and algorithm/unit
sections before the documentation rewrite is complete.
