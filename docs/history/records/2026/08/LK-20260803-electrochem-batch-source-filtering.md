# Electrochemistry batch imports retain compatible DTA files

```labkit-change
id: LK-20260803-electrochem-batch-source-filtering
date: 2026-08-03
sequence: 170
type: fix
compatibility: compatible
component: `labkit.app` | `2.2.0 -> 2.3.0`
component: `labkit_ChronoOverlay_app` | `1.6.1 -> 1.6.2`
component: `labkit_CIC_app` | `1.6.1 -> 1.6.2`
component: `labkit_CSC_app` | `1.6.1 -> 1.6.2`
component: `labkit_EIS_app` | `1.6.1 -> 1.6.2`
component: `labkit_VTResistance_app` | `1.6.1 -> 1.6.2`
scope: Electrochemistry multi-file import
scope: Folder and recursive DTA filtering
scope: App SDK file-list path predicates
```

## Context

CIC, CSC, and VT Resistance configured their file dialogs for single
selection even though their workflows and exports support batches. Folder and
recursive-folder actions selected every `.DTA` path by extension, so a folder
containing another Gamry experiment type caused session reconstruction to
fail transactionally and discarded compatible files in the same batch.

## Decision and rationale

Extend the existing App SDK file-list contract with a domain-neutral batch
path predicate and a standard aggregate filtering notice. Keep experiment
type detection in each electrochemistry App through the DTA facade: the SDK
owns selection lifecycle and interaction consistency, while Apps retain the
scientific meaning of chrono, CV/CT, and EIS inputs.

## Changes

- Added `PathFilter` and `PathFilterDescription` to
  `labkit.app.layout.fileList`.
- Applied predicates only to newly proposed paths, retained previously
  accepted sources, validated the returned logical mask, and omitted rejected
  paths before portable source records were created.
- Added one aggregate, filename-free notice when unsupported files are
  filtered.
- Enabled native multi-file selection for CIC, CSC, and VT Resistance.
- Declared chrono, CV/CT, or EIS predicates for all five electrochemistry Apps.

## User and data impact

Users can select several files at once and import a folder or folder tree even
when it contains other DTA experiment types. Matching files keep their order
and portable identities; unsupported paths are not stored. The notice reports
counts only and does not expose source filenames or paths. Source files and
saved project schemas are unchanged.

## Compatibility and migration

The change is compatible. Existing projects reopen without migration, existing
accepted sources remain registered, and Apps requiring `labkit.app >=2 <3`
remain within that range. Scientific formulas, units, analysis parameters,
result schemas, and export values are unchanged.

## Validation

Focused App SDK source specifications cover callback signature validation,
batch mask application, preservation of existing sources, portable-source
alignment, and aggregate notice wording. App-owned source specifications cover
chrono, CV/CT, and EIS discrimination. One existing hidden-GUI workflow per
electrochemistry App covers the mixed batch through plotting, analysis,
export, and project restore; CIC, CSC, and VT Resistance also verify native
multiple selection.

## Evidence

- App SDK plus five App source specification files: 29 identities passed.
- Five electrochemistry hidden-GUI workflow specification files: 5 identities
  passed.
- Authored-link validation checked 252 Markdown sources with no unresolved
  links; deterministic documentation generation compared 382 files across
  two independent renders.

## Known limitations and follow-up

Automated tests do not operate native file and folder dialogs or prove
behavior on approved laboratory data. The predicates use the supported DTA
content detector; a malformed file that cannot be classified is intentionally
reported as filtered rather than registered as an analysis source.
