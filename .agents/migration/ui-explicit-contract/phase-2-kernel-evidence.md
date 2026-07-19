# UI explicit-contract Phase 2 kernel evidence

Status: in progress on 2026-07-19.

The first production slices establish the GUI-free static contract graph. They
add sealed `labkit.ui.Application`, `Command`, `Layout`, and `Presentation`
values, strict canonical Name-Value parsing, fixed callback-role arity,
single-parent layout ownership, global ID/reference checks, target capability
checks, renderer ownership, and complete presentation-snapshot validation.
`ProjectContract`, `ResultOutput`, and `Result` now own the durable callback
and manifest boundaries without interpreting App scientific payloads.
`TableEdit`, `Selection`, and `DialogResult` replace ambiguous multi-field
event and cancellation transport.

`Layout` now implements the fourteen audited semantic concepts through one
class: `action`, `field`, `rangeField`, `panner`, `filePanel`, `previewArea`,
`resultTable`, `logPanel`, `statusPanel`, `group`, `section`, `tab`,
`workspace`, and `workbench`. The disposable `root`, `table`, and `preview`
prototype vocabulary was removed instead of becoming a compatibility alias.
Workspace pages are owned fluent values with compile-time initial-page checks.

The slice deliberately does not call `labkit.ui.runtime.define`, reuse current
layout structs, or introduce a compatibility adapter. Static layout flattening
is performed once by `Application`; repeated presentation validation consumes
the cached target graph.

Focused evidence:

- `UiExplicitContractKernelTest`: 5 of 5 tests passed.
- `UiExplicitContractValueTest`: 5 of 5 tests passed.
- `PublicApiDocumentationContractTest`: new class help contracts passed.
- `PackagePublicSurfaceTest`: the four replacement classes are explicitly
  governed.
- The documentation renderer discovers public `classdef` files from source
  paths and emits their local HTML reference pages without catalog entries.
- Narrative API tables are derived from exact source mentions, so adding one
  public symbol no longer injects the full facade list into unrelated history
  pages.

This is not the Phase 2 completion record. Deterministic diagnostic rendering,
the remaining accepted runtime-context surface, and exhaustive negative tests
remain open before the Phase 2 gate can close.
