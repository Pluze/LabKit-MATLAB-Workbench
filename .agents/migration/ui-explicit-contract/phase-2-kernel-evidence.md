# UI explicit-contract Phase 2 kernel evidence

Status: in progress on 2026-07-19.

The first production slice establishes the GUI-free static contract graph. It
adds sealed `labkit.ui.Application`, `Command`, `Layout`, and `Presentation`
values, strict canonical Name-Value parsing, fixed callback-role arity,
single-parent layout ownership, global ID/reference checks, target capability
checks, renderer ownership, and complete presentation-snapshot validation.

The slice deliberately does not call `labkit.ui.runtime.define`, reuse current
layout structs, or introduce a compatibility adapter. Static layout flattening
is performed once by `Application`; repeated presentation validation consumes
the cached target graph.

Focused evidence:

- `UiExplicitContractKernelTest`: 4 of 4 tests passed.
- `PublicApiDocumentationContractTest`: new class help contracts passed.
- `PackagePublicSurfaceTest`: the four replacement classes are explicitly
  governed.
- The documentation renderer discovers public `classdef` files from source
  paths and emits their local HTML reference pages without catalog entries.
- Narrative API tables are derived from exact source mentions, so adding one
  public symbol no longer injects the full facade list into unrelated history
  pages.

This is not the Phase 2 completion record. Signal payload values, deterministic
diagnostic rendering, the remaining accepted public values, and exhaustive
negative tests remain open before the Phase 2 gate can close.
