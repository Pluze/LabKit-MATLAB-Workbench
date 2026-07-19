# UI explicit-contract Phase 3 runtime evidence

Status: first GUI-free runtime checkpoint accepted on 2026-07-19; platform,
project, result, and interaction completion remain in progress.

The replacement runtime now executes a compiled `Application` without the
retired dispatcher, service bag, presentation commit schema, or control
registry. `RuntimeKernel` owns a FIFO command queue, validates the
project/session boundary after every callback, derives a complete immutable
`Presentation`, and commits it transactionally through a replaceable platform
adapter. A failed callback, state validation, presentation, or adapter commit
restores the previous state and presentation and reports the stable
`labkit:ui:runtime:ActionFailed` boundary.

`ResourceStore` establishes runtime-owned event, interaction, document, and
application lifetimes. Replacement and removal dispose exactly once. Scope
cleanup removes entries before invoking cleanup callbacks, continues after
individual failures, and reports the collected failure only after all selected
resources have been attempted. Closing a runtime is idempotent.

The implementation classes are sealed and hidden. MATLAB does not permit
package class definitions in a `private` directory, so the files live at the
`labkit.ui` package root with constructors and adapter operations restricted
to their owning replacement classes. Documentation discovery explicitly
excludes hidden classes, and the package surface guard records their presence
without treating them as App-facing contracts.

Focused evidence:

- `UiRuntimeKernelTest`: 5 of 5 tests passed, covering FIFO reentrancy,
  commit rollback, typed dispatch payloads, replacement/close cleanup, and
  cleanup-failure continuation.
- `UiRuntimeContextContractTest`: 2 of 2 tests passed.
- `PublicApiDocumentationContractTest`: 8 of 8 tests passed.
- `ProjectDocumentationGuardrailTest`: the public-function contract check
  distinguishes public value classes from function files.
- `PackagePublicSurfaceTest`: the three hidden implementation files are
  explicitly governed.
- `renderLabKitDocs`: 195 narrative pages and 146 public API pages generated
  with no tracked site diff; hidden runtime implementation classes produced no
  reference pages.

This checkpoint does not close Phase 3. The next slice must replace the
headless adapter with the private MATLAB component/layout adapter and connect
accepted project/recovery, result-writing, renderer, and viewport contracts
before the RFC examples are independent of the retired runtime.
