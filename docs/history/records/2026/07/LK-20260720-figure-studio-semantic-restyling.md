# Figure Studio preserves common graphics and styles semantic categories

```labkit-change
schema: 2
id: LK-20260720-figure-studio-semantic-restyling
date: 2026-07-20
sequence: 145
type: feat
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.3.1 -> 0.4.0`
component: `labkit.app` | `1.2.0 -> 1.2.1`
scope: Figure Studio
scope: App Framework GUI validation
scope: Test runner
```

## Context

Figures sent from Apps, reopened from FIG files, or recreated from Figure
Studio data packages could omit common composite graphics such as bars,
error bars, areas, and rectangles. Legends were reconstructed only from
display names, and the preset exposed one broad line-width control. This made
restyling incomplete and could enlarge unrelated text enough to overlap data.
Separately, the official hidden-GUI policy was applied while native App windows
were constructed but the final show operation could make direct-entrypoint
tests visible.

## Decision and rationale

Preserve the supported visible plot structure before applying a presentation
preset. Style text and strokes by semantic role so users can establish a
coherent baseline and then refine categories that have different visual
weights. A preset may style an existing legend, but it retains source
placement by default because moving or creating a legend can cover data.

Keep GUI-test visibility in the private native adapter. App authors and test
methods should not maintain a second hiding convention, and no new public API
is needed for a framework-owned launch consistency rule.

Keep broad tests in one MATLAB process. A complete local comparison showed
that three workers increased both wall-clock and CPU time, so portability work
around child-process orchestration would preserve cost without user benefit.

## Changes

- Added bar, error-bar, area, and display-only rectangle extraction and
  reconstruction for previews, FIG imports, and portable recreation scripts.
- Preserved constant-line labels without interpreting scientific text as a
  MATLAB line specification.
- Preserved existing legend text, visibility, placement, orientation, columns,
  font, interpreter, and border through every supported reconstruction path.
- Preserved explicit axis ticks, tick labels, rotations, locations, and tick
  geometry instead of asking MATLAB to infer them again during reconstruction.
- Included visible hidden-handle graphics in snapshots while retaining their
  exclusion from automatic legend discovery.
- Made the LabKit preset the initial style for direct plot handoff while
  retaining the captured source style as **FIG default**.
- Added separate controls for title, axis-label, tick, annotation, legend,
  data, uncertainty, graphic-boundary, reference, and axes styling, plus
  source/horizontal/45-degree X tick labels.
- Calibrated the LabKit preset against a representative standard Figure:
  a 720-by-600 reference canvas, 24/20/15 pt semantic text tiers, 1.1/1.2 pt
  semantic strokes, Helvetica when available, boxed axes and legend, and a
  600 dpi export at the default scale.
- Scaled text and strokes dynamically from each style's reference canvas while
  compensating for preview fitting, and reduced UI steps to 0.5 pt for fonts,
  0.1 pt for strokes, and 10 px for canvas dimensions.
- Migrated schema 1 projects to the expanded semantic style model while
  preserving every previously saved style value.
- Made the final native show operation honor hidden and minimized GUI
  validation modes.
- Bound heartbeat work at timer creation so path-isolation contracts cannot
  remove a method needed by an active progress callback.
- Removed internal worker planning, partitioning, process launch, shard
  selectors, and speculative JUnit shard estimates. Local and CI broad tasks
  now share the same single-process runner.

## Compatibility and user impact

Existing schema 1 documents migrate automatically to schema 2, keeping saved
values and supplying defaults only for newly introduced style categories.
Supported figures retain more visible content, while unsupported MATLAB chart
classes continue to produce explicit warnings. Normal App launches remain
visible; only official hidden or minimized validation modes change final
window presentation.

## Validation and evidence

- Result-file tests exercise extraction, FIG reopening, recreation-script
  execution, legend metadata, constant-line labels, semantic styling, and
  idempotent preset application.
- Figure Studio source-axis and hidden-GUI suites cover source defaults,
  LabKit handoff defaults, the new control surface, preview stability, and
  popout handoff. Project tests cover schema 1 style migration.
- Framework GUI coverage verifies that the final show operation retains
  hidden mode, and a direct DIC Preprocess entrypoint test exercises the full
  launch path.
- A same-machine cold-process comparison measured 470 seconds wall time and
  876 seconds CPU time for the serial headless gate versus 490 seconds wall
  time and 1,215 seconds CPU time for three workers. Worker artifacts also
  confirmed that heartbeat updates survived the isolated-path contract.

## Follow-up

Developer-led visual review remains responsible for aesthetic judgment,
unusual third-party chart classes, native window behavior, and plot-specific
overlap after manual legend placement.
