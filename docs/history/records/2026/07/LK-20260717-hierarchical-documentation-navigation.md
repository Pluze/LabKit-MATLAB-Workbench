# Documentation navigation follows topic hierarchy

```labkit-change
id: LK-20260717-hierarchical-documentation-navigation
date: 2026-07-17
sequence: 132
type: docs
compatibility: compatible
scope: MATLAB documentation site navigation
```

## Context

The documentation site exposed its major areas in the top bar, but each
area's left sidebar was a flat list. Related app families, development tasks,
and API packages were not visually distinguished, so readers could not readily
see the path from an area to a topic and then to a specific page.

## Decision and rationale

Render contextual hierarchy from the existing page and catalog metadata.
App families, libraries, development tasks, and MATLAB packages become labeled
sidebar branches. This preserves one structured source of navigation truth
while making downstream topics visible from their area landing pages.

## Changes

- Grouped app navigation by family and indented app manuals below family
  pages.
- Grouped function, framework, and development navigation by topic.
- Grouped API siblings under their owning MATLAB package.
- Defined the second `nav` entry in `docs/site.json` as the branch label and
  ordered branches by their earliest page.
- Added responsive sidebar styling and renderer regression coverage for the
  hierarchy.

## User and data impact

Readers can move from a top-level area to a topic branch and then to a specific
manual without searching a flat list. Documentation content, URLs, MATLAB
behavior, and scientific data are unchanged.

## Compatibility and migration

Existing page URLs and top-level navigation remain compatible. Documentation
authors should assign new multi-page topics a stable second-level `nav` label
in `docs/site.json`.

## Validation

The documentation renderer regression verifies Development topic groups, App
family branches, and API package labels. `docsCheck` rebuilds and compares the
complete generated site.

## Evidence

The generated area landing pages contain labeled branch headings and
parent/child link classes derived from tracked page and app catalog metadata.

## Known limitations and follow-up

Single-page areas do not display an artificial empty branch. History records
remain in the generated timeline because reproducing the full record set in
the sidebar would make navigation less usable.
