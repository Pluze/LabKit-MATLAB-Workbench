# App SDK improves diagnostics, artifacts, and input workflows

```labkit-change
id: CHG-20260803-app-sdk-diagnostics-and-input-workflows
date: 2026-08-03
type: feat
compatibility: compatible
component: labkit.app | 2.1.0 -> 2.2.0
```

## Why

The standard Session Log combined a severity selector with a second audience view, presented an unexplained Default choice, and exposed a pause-follow control that did not improve diagnosis. TRACE normally contained no more useful detail than DEBUG because capture was off and Runtime emitted few trace stages. Diagnostic ZIP export also asked for a destination before every attempt, offered a redacted projection that did not reliably remove scientific values, and could emit a potentially large App-state MAT without distinguishing exact reproduction from structurally sufficient evidence, while screenshot and project-state saves required manual naming and destination selection. Successful diagnostic export used MATLAB's default error icon. File collections lacked a shared content predicate and native error-alert fallback, and the paired-anchor interaction could inherit a connecting path that implied meaning the App did not own. These were separate development checkpoints but one pending App SDK transition from the mainline baseline. The same Runtime immediately painted busy feedback around every callback, which made quick actions flash, while long actions did not freeze mutable controls or reject reentrant UI input consistently. The SDK's private implementation had also accumulated unrelated contract, native, diagnostics, storage, launcher, and runtime classes in one internal root. Downstream App specifications named those private classes directly, so an ownership-only reorganization broke otherwise valid private App evidence.

### Accepted choice

Use one three-level display contract while keeping capture cost independent of the selected view. Retain DEBUG and higher during ordinary operation, enable TRACE automatically after the first error, and keep an explicit capture toggle inside the owning log window. Give TRACE distinct transaction and presentation stage records. Treat the repository artifacts area as the first destination for diagnostics, screenshots, and project state, generate App-specific names, and ask for another location only after automatic output fails. Retain full diagnostic details in memory, the viewer, local journal, and every bundle. Always include App state because parameter, annotation, result, and cache state cannot be reconstructed from the event timeline. Offer exact state and a compact structural variant. Compact state recursively replaces supported leaves larger than 1 MiB with deterministic, compressible values of the same class and dimensions, and reports every replacement without recording its content. Do not present either bundle as privacy-safe. Complete the same SDK transition with a domain-neutral file-list predicate, aggregate rejection notice, native file-action failure alert, and an explicit point-only paired-anchor mode. Order open-path additions by their nearest visible location so prepend, interior insertion, and append behavior does not change with zoom. Apps continue to own file-type meaning, alert wording they handle directly, and scientific interaction semantics. Enter busy state immediately but defer its native presentation for 250 ms. This preserves transactional exclusion without showing a transient pointer, title, or disabled-control frame for short actions. Once feedback is visible, freeze mutable controls and let user-facing diagnostic messages update the current stage; restore the final committed Snapshot when work ends. Group every SDK internal implementation by one named subsystem and split the largest launcher and runtime owners along existing workflow boundaries. Keep white-box SDK specifications free to test private behavior, but route public and accepted-private App specifications through focused `labkittest` seams so internal package movement has one test-owned compatibility boundary. When equal screen units are requested, use MATLAB's native data-aspect-ratio contract while retaining the fitted data limits. This preserves one visual scale without inferring it from version-specific tiled-layout pixel geometry.

## What changed

- The viewer now offers Full TRACE, DEBUG, and User levels, defaults to Full TRACE, follows new records continuously, and removes the duplicate View and pause-follow controls.
- Each viewer title names its owning App, and manual TRACE capture lives in the viewer instead of the App Tools menu.
- Selecting an event in the viewer highlights its complete row while retaining the same structured-detail inspection behavior.
- ERROR and CRITICAL records enable TRACE capture for later activity; trace records now distinguish state update, validation, presentation, native commit, and rollback cleanup stages.
- Diagnostic export generates a unique App-specific filename beneath `artifacts/diagnostics/`; its text fallback uses the same base name, and a prefilled save dialog appears only when automatic output fails.
- Each diagnostic export contains complete-sensitive events and prompts for exact `app-state.mat` or `app-state-compact.mat`. Compact mode preserves state structure and small diagnostic values while replacing supported leaves over 1 MiB with synthetic compressible placeholders. `bundle-report.json` records the mode, MAT size, and replacement paths, types, dimensions, and original byte counts, plus any oversized unsupported leaf types retained unchanged. Text fallback preserves complete events and reports that the selected MAT cannot be represented as text.
- Screenshot and project-state saves now generate App-specific names beneath `artifacts/screenshots/` and `artifacts/states/`, with chooser fallback only when automatic output fails.
- Successful utility exports use an information icon rather than MATLAB's default error icon.
- File lists can apply a caller-owned predicate to newly proposed paths, preserve accepted sources, and report aggregate kept/rejected counts without retaining rejected filenames or paths.
- Native file-panel actions surface otherwise-unhandled validation or parsing failures in an error alert after transactional rollback.
- Paired-anchor interactions force point rendering without a connecting path.
- Open anchor paths prepend beyond the visible start, append beyond the visible end, and insert other additions into the nearest visible segment independent of axes zoom.
- Public plot-area help and the Runtime guide document how vertically arranged workspace-page content composes paired plot rows, including fixed-width scale or histogram columns, without App-owned native containers.
- Runtime now blocks reentrant control and interaction callbacks immediately, displays busy feedback only after a short delay, freezes native inputs for longer work, updates the visible stage from user-facing log events, and restores final enabled states from the committed Snapshot.
- App SDK internals now live under explicit artifact, contract, diagnostics, interaction, launcher, native, project, resource, result, runtime, and source owners; the launcher dispatcher and Runtime kernel delegate cohesive workflows to focused files instead of retaining mixed monoliths.
- Downstream App and conformance specifications now use concentrated `labkittest` seams for runtime construction, callback contexts, definition inspection, and synthetic input generation. SDK-owned white-box tests retain direct internal access, and a repository guard prevents App-spec leakage.
- Equal-data-unit plot fitting now uses a native manual data aspect ratio instead of axes outer-box pixel geometry, including on the supported R2022b validation profile.

## Impact

Users can distinguish concurrent App logs, select a meaningful amount of detail with one control, and export diagnostics without choosing a path. The local journal, Session Log, every export, and every fallback may contain paths, filenames, scientific values, and exception locations. Every ZIP includes current project and session state. Exact state retains decoded caches; compact state replaces only individually large supported values and is not scientifically valid input. External source files and screenshots are not attached separately. Apps can accept mixed batch selections without losing compatible inputs, and unhandled source failures are visible instead of remaining callback output. App authors can discover the existing multi-row plot composition pattern from both the function help and the framework guide. Quick actions no longer flash busy chrome. Long actions prevent repeated submission and parameter edits while retaining App-owned stage wording.

## Compatibility and limits

The App SDK change is compatible with existing version-2 App requirements and does not change callback logging syntax, canonical event fields, projects, or results. Existing App definitions require no migration. The removed Tools-menu TRACE item was a Runtime utility, not an App-facing API; the same manual ability is available in the Session Log window. Internal class paths are not an App-facing compatibility contract; downstream production Apps contain no such references, and downstream tests use the repository-owned test seams.

### Remaining limits

TRACE cannot reconstruct stages that occurred before capture was enabled. A process termination before Runtime records a terminal event still leaves only the last successfully retained boundary. Native visual density and dialog feel remain manual review boundaries.
