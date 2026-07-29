# Cross-version dialogs and Batch Crop duplication keep portable shapes

```labkit-change
id: LK-20260729-cross-version-dialog-and-duplicate-repair
date: 2026-07-29
sequence: 162
type: fix
compatibility: compatible
component: `labkit.app` | `2.0.1 -> 2.0.3`
component: `labkit_BatchImageCrop_app` | `1.9.0 -> 1.9.1`
component: `labkit_FigureStudio_app` | `0.7.0 -> 0.7.1`
scope: Windows MATLAB file-dialog filter compatibility
scope: Batch Crop duplicate task shape alignment
scope: diagnostic text fallback
scope: Figure Studio R2022b graphics export and layout
scope: oldest/latest MATLAB CI compatibility matrix
```

## Context

MATLAB R2024b on Windows rejected string-valued cells passed to `uiputfile`
while exporting a diagnostic ZIP. Batch Crop also inserted a duplicate with
vertical concatenation even when the native file-list source binding supplied
a row struct array, so duplicating from a multi-image list could fail with a
dimension mismatch.

## Decision and rationale

The private MATLAB adapter now uses its existing dialog-filter normalizer for
ordinary input and output dialogs. Batch Crop normalizes its four parallel task
collections to columns at the duplicate callback boundary before inserting the
new task. These are the narrow owners of the platform and App shape contracts;
no new public API or saved-project migration is needed.

The App SDK also canonicalizes text at the portable-source, source-resolution,
and native file-label boundaries: a character vector is one scalar value,
while string and cellstr collections become columns where the owning contract
requires a collection. Apps continue to own ordinary file reading and writing;
an architecture guardrail only prevents them from bypassing `fileList` or
`CallbackContext` for native file and folder dialogs.

Diagnostic export now treats a ZIP failure as a degraded but recoverable
Runtime outcome. It writes the already-sanitized in-memory session records to
one text file beside the chosen destination when possible, or in MATLAB's
user-writable temporary folder otherwise. This remains private Runtime
behavior because Apps neither select nor interpret diagnostic formats.

Figure Studio now selects graphics primitives at its result-file boundary.
R2025a and newer retain `exportgraphics` figure padding; supported older
releases use `print`, including its SVG device. Invisible export figures are
anchored before their drawable pixel size is assigned, then layout converges
against the native renderer's measured text extents. A final figure-coordinate
fit catches older Windows renderers that update ruler-label extents only after
accepting the offscreen geometry. If R2022b clamps that invisible figure to the
desktop despite the requested size, Figure Studio recomputes the data frame
from the accepted drawable canvas after reserving measured label and tick
insets. Font size remains unchanged, while the constrained plot frame yields
enough real outer whitespace for ordinary ruler labels. Titles and axis labels
are included explicitly because R2022b does not consistently expose those
ruler decorators through descendant text discovery.

## Changes

- Converted native input/output dialog filters to character-cell tables before
  calling `uigetfile` or `uiputfile`.
- Canonicalized scalar character paths and IDs before collection reshaping,
  including Unicode, duplicate, drive-letter, and UNC-shaped regression cases.
- Added a repository guardrail requiring Apps to use the SDK-owned native file
  dialog boundaries without introducing a generic public file API.
- Made Batch Crop duplicate insertion preserve one column-aligned task, source,
  image-cache, and path-cache row per list entry.
- Added focused regression coverage for the R2024b-compatible filter value and
  a multi-image row-shaped duplicate state.
- Expanded every validation profile from one fixed MATLAB release to the
  supported R2022b floor and the latest release available to the official
  setup action. macOS remains a latest-release platform sentinel.
- Grouped the three validation profiles by platform and release so each matrix
  entry installs MATLAB once while each profile retains a fresh batch session.
- Bound the R2022b entries to Ubuntu 22.04 and Windows Server 2022 runner
  images supported by that release instead of testing unsupported latest
  operating-system images.
- Gave Linux MATLAB sessions an X virtual framebuffer so hidden-GUI tests do
  not depend on release-specific behavior when no display server is active.
- Added a single-file diagnostic fallback for native dialog, ZIP staging, ZIP
  creation, and publish failures, with the resulting path reported to the user.
- Kept Figure Studio raster and SVG export operational on R2022b, where
  `exportgraphics` has neither figure padding nor SVG support.
- Reserved measured label and tick margins in hidden export canvases. The
  normal path preserves the configured plot frame; if Windows refuses the
  requested outer size, the final fit reduces only the rendered data frame to
  keep those margins inside the accepted canvas.
- Retained deterministic production-rendered PNGs below each test profile's
  `visual-evidence/` folder, included them in the existing platform artifact,
  and kept automated assertions over the same files.
- Replaced three disconnected raw test summaries with one platform-level
  compatibility report that explains each profile, success caveats, actionable
  failure diagnostics, slow-test signals, and exact artifact ownership.
  Cancelled or skipped profiles now report an incomplete conclusion instead of
  mislabeling missing evidence as a compatibility failure.

## User and data impact

Windows users can choose a destination for diagnostic ZIP bundles, projects,
screenshots, plots, and other Runtime output dialogs. Batch Crop can duplicate
an image task from a multi-image list without changing source images or prior
task settings. If diagnostic ZIP export still fails, users receive the path to
a readable plain-text fallback containing the surviving sanitized session
history. Figure Studio keeps complete ruler labels and styled figure output
across the supported MATLAB release boundary. A Windows desktop that refuses
the requested outer canvas can constrain the rendered data-frame size without
changing the saved project setting.

## Compatibility and migration

The repair is backward compatible. Public App SDK signatures, Batch Crop
project payload version 3, scientific crop calculations, and exported result
schemas are unchanged.

## Validation

Focused headless specifications cover the Batch Crop duplicate callback and
the native dialog-filter value, diagnostic ZIP-to-text degradation, and Figure
Studio result layout. The ruler-label regression uses the production PNG
export path and checks its bottom and left whitespace rather than treating
hidden-window geometry as export evidence. Hidden-GUI workflow coverage also
performs a real PNG export.
CI runs every full profile on Linux, macOS, and Windows against R2022b and the
latest available MATLAB release, while macOS runs the latest release. The
R2022b jobs use fixed supported runner images; latest MATLAB uses current
runner images, and Linux GUI validation runs with a virtual display.
The JUnit artifact records MathWorks qualification and exception diagnostics
instead of a generic failure placeholder, and dependency-free Python
regressions protect both successful and failed summary layouts. Documentation
consistency and the final changed-file gate cover the integrated version and
history updates.

## Evidence

The repair branch records focused MATLAB test artifacts and the final
changed-file validation result. The supplied sanitized log identifies the
original `MATLAB:catenate:dimensionMismatch` and
`MATLAB:character:CellsMustContainChars` failures.

## Known limitations and follow-up

Automated tests cannot prove the appearance and interaction quality of the
native Windows save dialog. A manual MATLAB R2024b Windows check remains the
final platform acceptance boundary.
