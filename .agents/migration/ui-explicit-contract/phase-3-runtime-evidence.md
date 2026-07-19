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

`ProjectDocumentStore` now writes and restores the accepted
`labkit.project` envelope without exposing document metadata to App callbacks.
It accepts only the current envelope or an import explicitly declared by
`ProjectContract`, migrates payloads sequentially, rebuilds session/resume
state, and publishes restored state and document identity only after
presentation reconciliation succeeds. `ResultWriter` verifies declared output
files, records byte counts and SHA-256 values, derives aggregate status, and
atomically writes the fixed `Result.ManifestName`; output creation remains
App-owned.

The platform inventory found one contract omission before App migration:
opaque portable records had creation/reconciliation methods but no supported
way for App code to obtain resolved paths. `RuntimeContext.sourcePaths`
therefore joins the existing declared `project` capability after a cross-App
inventory confirmed that source-path reads are required by the file-backed
Apps. It returns a column string array and does not expose the portable
reference representation.

The authoring-ergonomics hardening pass also establishes the paved road:
Layout signals are collected automatically instead of being repeated in
Application, strict `project.*`/`session.*` bindings remove mechanical
callbacks and presenter operations, runtime defaults plus bindings form the
complete snapshot, `ProjectContract()` supplies the simple version-1 scalar
struct contract, omitted capability metadata selects the standard capability
set, and `appendStatus(message)` is unambiguously framework-owned. The
executable budgets live in `UiAuthoringErgonomicsTest` and
`authoring-ergonomics.md`.

The implementation classes are sealed and hidden. MATLAB does not permit
package class definitions in a `private` directory, so the files live at the
`labkit.ui` package root with constructors and adapter operations restricted
to their owning replacement classes. Documentation discovery explicitly
excludes hidden classes, and the package surface guard records their presence
without treating them as App-facing contracts.

Focused evidence:

- `UiRuntimeKernelTest`: 6 of 6 tests passed, covering FIFO reentrancy,
  commit rollback, typed dispatch payloads, replacement/close cleanup, and
  cleanup-failure continuation plus bound updates.
- `UiRuntimeContextContractTest`: 2 of 2 tests passed.
- `UiAuthoringErgonomicsTest`: 5 of 5 executable paved-road budgets passed.
- `UiPortableSourceStoreTest`: 3 of 3 runtime-boundary tests passed.
- `UiProjectDocumentStoreTest`: 7 of 7 tests passed, including atomic save,
  migration/import, wrong/newer rejection, recovery identity, failed-save
  metadata isolation, adapter-commit rollback, bound-source rebasing, and
  missing-required-source rejection.
- `UiResultWriterTest`: 4 of 4 tests passed, covering verified output
  metadata, missing output failure, aggregate status, and atomic cleanup.
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
dialogs, portable sources, renderer, and viewport contracts before the RFC
examples are independent of the retired runtime.
