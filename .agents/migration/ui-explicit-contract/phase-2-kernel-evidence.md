# UI explicit-contract Phase 2 kernel evidence

> Naming amendment (2026-07-19): this evidence predates the final
> `labkit.app` package split. Its `labkit.ui` explicit-value names are
> historical prototype names, not the SDK surface.

Status: accepted on 2026-07-19.

The first production slices establish the GUI-free static contract graph. They
add sealed `labkit.ui.Application`, `Command`, `Layout`, and `Presentation`
values, strict canonical Name-Value parsing, fixed callback-role arity,
single-parent layout ownership, global ID/reference checks, target capability
checks, renderer ownership, and complete presentation-snapshot validation.
`ProjectContract`, `ResultOutput`, and `Result` now own the durable callback
and manifest boundaries without interpreting App scientific payloads.
`TableEdit`, `Selection`, and `DialogResult` replace ambiguous multi-field
event and cancellation transport.
`RuntimeContext` is a sealed direct-method capability boundary backed by a
private operation implementation. It enforces the Application allow-list
before every call and exposes neither the backend nor a nested service bag.
The public zero-capability constructor supports callbacks that must remain
pure; runtime construction is hidden.

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
- `UiRuntimeContextContractTest`: 2 of 2 tests passed.
- `UiExplicitContractClosureTest`: 4 of 4 tests passed.
- `PublicApiDocumentationContractTest`: new class help contracts passed.
- `PackagePublicSurfaceTest`: every replacement class is explicitly governed.
- The documentation renderer discovers public `classdef` files from source
  paths and emits their local HTML reference pages without catalog entries.
- Narrative API tables are derived from exact source mentions, so adding one
  public symbol no longer injects the full facade list into unrelated history
  pages.

The Phase 2 gate is closed. Malformed definitions fail before a compiled
Application is returned; canonical spelling, fixed callback shapes, direct
Command bindings, typed multi-field payloads, complete snapshots, layout
ownership, capabilities, references, and deterministic contract diagnostics
all have focused negative coverage. Phase 3 may connect this compiled plan to
the transactional runtime and private MATLAB platform adapter.
