# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; completed work belongs in component history.

## Active debt

Last audited: 2026-07-25.

```text
toolbox-product-debt: none
architecture-migration-debt: unified session logging and incident diagnostics
compatibility-retirement-debt: debug launch and split status/diagnostic APIs
```

## Unified session logging and incident diagnostics

### Implementation hold and agent coordination

Status: **repair-only Launcher architecture approved; continue only through the ordered checkpoints below**.

Any agent working on this migration must stop before adding more App migrations,
committing the current all-App batch, or treating a draft `SessionJournal`,
viewer, or `CallbackContext.log` implementation as an accepted contract.
Preserve existing work, inspect the shared worktree, and reread this complete
entry before continuing. Do not overwrite, discard, or silently reshape another
agent's uncommitted files.

Implementation may resume only as the ordered checkpoints below. In particular:

- preserve `labkit_launcher.m` as a self-contained **repair-only** entry that
  can run when `+labkit`, Apps, docs, or scripts are missing or damaged;
- do not add a bootstrap journal, bootstrap schema, session importer, or any
  second logging implementation to the repair entry; repair does not depend on
  a Runtime logger class;
- establish a privacy-safe semantic event before any persistent, exported, or
  default Log-viewer projection;
- prove the minimal in-memory stream and operation state machine before
  migrating every App;
- do not commit hundreds of framework, App, fixture, and compatibility changes
  as one checkpoint; isolate the contract, persistence, repair/delegation,
  viewer, synthetic-input rename, and App-family migrations;
- run the focused exit gate for a checkpoint before starting the next one.

An agent that discovers this hold while work is in progress must report which
checkpoint its current files represent, which later-phase files are already
present, and what remains unverified. It must not call a broad staged diff
“complete” merely because construction or one headless log test passes.

### Launcher ownership and repair boundary

The launcher has three separate layers:

1. `labkit_launcher.m` is the single-file rescue entry. It uses only native
   MATLAB for a boot-critical minimum check, user-visible repair errors, and
   the one GitHub ZIP repair transaction. It does not discover Apps, create
   Runtime diagnostics, or own a session journal.
2. A focused hidden installed capability under
   `+labkit/+app/+internal/+launcher/` (optionally behind one hidden `Launcher`
   facade) owns Launcher UI composition, catalog routing, and normal startup.
   It starts only after the rescue entry can call the installed entry. Once the
   SDK is loaded, Launcher actions use the canonical Runtime operation/session
   contract; no repair-to-Runtime handoff schema exists.
3. `tools/<owning-capability>/` owns only MATLAB tools with independent value:
   a callable entry, explicit inputs/results or observable side effect, stable
   error behavior, and independent tests/docs. Launcher-only callbacks, table
   formatting, status wording, menus, and routing remain with the installed
   Launcher. Existing docs, codecheck, profiling, and deployment tools are
   called directly with only necessary UI/path adaptation.

Version browsing or rollback is a `tools/deployment` candidate only when it
has an independent callable contract and invokes the root's unique repair
transaction; it must not copy ZIP replacement logic.

Repair detects incompleteness lazily. Rescue startup checks only that the
installed Launcher entry exists and is callable. If entry loading, dependency
resolution, or App startup fails structurally (for example a missing file or
undefined symbol), preserve the concrete error and offer GitHub repair. Do not
label ordinary scientific input, validation, or user-operation failures as an
incomplete install. ZIP candidate validation is deliberately narrower: require
a LabKit root, root launcher, installed entry, and expected `apps`/`+labkit`
top-level content before replacement. Packages may keep using
`packaged_app_manifest.json` for package semantics, but rescue does not require
it and this migration adds no install manifest, hash, or file inventory.

### User problem and current evidence

LabKit does not currently have one session log. It has several partially
overlapping channels:

- `CallbackContext.appendStatus` adds unstructured display strings to an
  unbounded `StatusLog`; every App exposes that row through a `logPanel`.
- `CallbackContext.reportError` records an exception in Runtime state and emits
  an event, but does not itself create a useful user-facing log row or alert.
- `DiagnosticRecorder` records structured lifecycle, operation, failure, and
  checkpoint events, but ordinary launches retain them only in memory. Disk
  recording is coupled to a verbose diagnostic launch.
- Launcher `Open Debug` combines two unrelated choices: verbose diagnostics and
  construction of a synthetic sample pack. A normal launch cannot later recover
  the same diagnostic history.
- Launcher failures are collapsed into one status message before an App Runtime
  exists. Direct App entrypoints and Launcher entrypoints therefore do not
  produce equivalent evidence.
- Framework documentation describes project, dialog, resource, and interaction
  tracing more broadly than Runtime currently instruments.
- Current tests exercise clean sample startup and a few manifest outcomes, but
  do not directly prove the recorder schema, sanitization, retention,
  degradation, operation ancestry, or an actual GUI callback-to-log workflow.

The visible result is a Log tab with too little context for users, while the
more useful evidence usually does not exist after an ordinary incident. The
same action can also produce different wording and detail depending on its
entry path.

### External design evidence

The target uses stable ideas from mature logging systems without adding a
third-party runtime or network dependency:

- The [OpenTelemetry Logs Data Model](https://opentelemetry.io/docs/specs/otel/logs/data-model/)
  separates timestamp, observed timestamp, severity, body, resource,
  instrumentation scope, attributes, event name, and trace/span correlation.
- [.NET logging](https://learn.microsoft.com/en-us/dotnet/core/extensions/logging/overview)
  separates categories and structured messages from provider-specific level
  filters, and uses scopes to correlate one operation. Its
  [providers](https://learn.microsoft.com/en-us/dotnet/core/extensions/logging/providers)
  demonstrate that one record can feed multiple independently filtered sinks.
- [Python logging](https://docs.python.org/3/howto/logging.html) separates
  loggers, handlers, levels, filters, and formatters. Its
  [rotating handlers](https://docs.python.org/3/library/logging.handlers.html)
  provide the retention pattern needed for a bounded local journal.
- [Qt logging categories](https://doc.qt.io/qt-6/qloggingcategory.html) make
  runtime category filtering independent of Debug versus Release builds and
  avoid formatting disabled detail.
- [Apple unified logging privacy](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code)
  treats dynamic user data as private rather than assuming every formatted
  value is safe to persist.
- [systemd-journald](https://www.freedesktop.org/software/systemd/man/latest/journald.conf.html)
  demonstrates bounded storage, independent sink thresholds, rate limits, and
  explicit accounting for discarded records.

The design consequence is that severity, capture detail, display detail,
persistence, synthetic inputs, and build configuration are independent axes.
There is no product-level “debug session” mode.

### Target product behavior

1. Every ordinary installed Launcher or direct App launch creates its canonical
   Runtime session only after the App SDK is available. The repair-only entry
   creates no log/session schema; it delegates when possible and otherwise
   offers repair for structural installation failure.
2. A bounded local flight recorder is always on. It captures sufficient
   structured `DEBUG`-and-higher evidence to diagnose a later failure without
   requiring the user to predict that failure. `TRACE` is opt-in because of its
   potential volume.
3. The App Log viewer shows concise, actionable user information. Its filter
   does not decide what the recorder captured and cannot erase earlier detail.
4. A user can export retained current-session history after a problem. Runtime
   archive recovery preserves safe evidence for abandoned sessions.
5. “Complete history” means the retained semantic action chain, state
   transitions, outcomes, durations, warnings, and exceptions. It does not mean
   raw scientific arrays, workspace snapshots, images, or every call frame.
6. Any retention, rate-limit, or sink failure is represented explicitly; the
   system must never pretend a truncated journal is complete.
7. Synthetic inputs are an explicit tool action. Generating them does not
   mutate current App state, load a project, start analysis, or change logging
   policy.

The framework-owned **Tools** menu keeps diagnostics out of each App's primary
scientific workflow:

```text
Tools
|- Diagnostics
|  |- Show Logs
|  |- Export Diagnostic Bundle
|  |- Copy Problem Summary
|  `- Clear View
`- Developer Tools
   |- Generate Synthetic Inputs
   `- Trace Capture
```

Display filtering belongs in the Log viewer. Trace capture and synthetic-input
generation are ordinary-session tools, not a separate launch mode.

`Clear Log View` clears only the current viewer projection. It does not silently
delete the flight recorder. `ERROR` leaves the App usable when recovery is
possible and exposes the correlation ID and export action. `CRITICAL` means the
session is not safe for further product actions; diagnostic export remains
available.

Launcher removes **Open Debug**. Repair failures remain user-visible repair
errors; diagnostics and export begin only after the installed SDK/Runtime is
available.

### Severity and audience contract

Use one spelling and one meaning everywhere:

| Level | Meaning | Default App view | Flight recorder |
| --- | --- | --- | --- |
| `TRACE` | High-volume implementation steps useful only for deep investigation | Hidden | Opt-in |
| `DEBUG` | Parameters, branch choices, counts, state transitions, and timings useful to a developer | Hidden | Captured with bounds |
| `INFO` | Normal user-meaningful progress or completion | Shown when useful | Captured |
| `WARNING` | Unexpected or degraded behavior from which the operation can continue or recover | Shown | Captured |
| `ERROR` | The requested operation failed, while the process/session may remain usable | Shown prominently | Captured with exception |
| `CRITICAL` | The session is unsafe or a required foundation failed | Shown prominently | Captured and flushed |

Severity is not an audience. Each record also declares
`Audience="user"|"developer"`. A developer-oriented warning remains a warning;
the viewer may hide it from its default user projection only when it cannot
help the user act. All `WARNING`-and-higher records are visible by default
unless the message is explicitly marked as an internal duplicate of another
user-facing record.

Do not use `INFO` as a callback trace, `WARNING` for ordinary validation
guidance, or `ERROR` merely because a fallback was used successfully. Expected
invalid user input stays inline validation unless it changed state or caused an
operation to fail.

### Canonical structured record

The repository owns a minimal versioned record schema. Schema v1 contains:

```text
schemaVersion
sequence
timestampUtc
elapsedSeconds

severity
audience
category
eventName
message
attributes

sessionId
appId
operationId
parentOperationId
rootActionId

operationResult
stateDisposition
durationSeconds
exception
```

Do not persist `observedTimestampUtc` until an asynchronous or cross-process
collector makes it observably different from the event timestamp. Derive the
OpenTelemetry severity number from `severity` in an export projection instead
of storing two authorities. Store App, App SDK, MATLAB, platform, capture
policy, and resolved-entrypoint facts once in the session manifest rather than
repeating them in every event. Source function/line belongs only in a sanitized
exception stack or an explicit developer checkpoint; it is not a routine
record field or stable public contract.

`operationResult` and `stateDisposition` are independent. An operation that
throws after the Runtime restores its transaction records
`operationResult=failed` and `stateDisposition=rolledBack`; it never uses
`rolledBack` as a competing result value. The schema uses the two explicit
top-level fields rather than a scalar-or-struct compatibility shape.

`message` is privacy-safe readable prose and may evolve. It must not contain a
raw path, original filename, user/subject/device/sample identifier, or
scientific value copied from an input. `eventName` and attribute keys are the
machine-stable contract used by tests and diagnostic tooling. Attributes are
deny-by-default: finite scalar numeric/logical values, controlled enum/unit/
reason/Runtime-alias text, and an explicitly bounded dimensions shape are the
only ordinary retained values. Attribute validation enforces nesting, field,
and serialized-byte limits. It rejects subject, device-serial, sample, signal,
and other identifier/scientific-value fields; numeric arrays; arbitrary free
text; handles; classes; graphics objects; tables; and workspace values before
the event enters memory, a projection, or disk.

Operation ancestry, not a full call stack on every line, reconstructs the
normal action chain. A root user action creates `rootActionId`; nested Runtime
and App operations create parent-linked IDs. A full sanitized exception stack
is captured at `ERROR` and `CRITICAL`, and may be requested for an explicit
diagnostic checkpoint. This keeps routine logging useful without turning it
into a profiler.

Framework category roots are stable:

```text
launcher.lifecycle
runtime.lifecycle
runtime.callback
runtime.presentation
runtime.project
runtime.source
runtime.dialog
runtime.result
runtime.resource
runtime.interaction
app.<appId>.<capability>
```

Examples of stable event names are `session.started`, `callback.started`,
`callback.completed`, `callback.failed`, `project.opened`,
`source.validation_failed`, `analysis.completed`, `result.exported`, and
`journal.records_dropped`. Messages and attributes may provide App-specific
detail without inventing competing event vocabularies.

### App-facing API and ownership

Extend the existing sealed `labkit.app.CallbackContext`; do not expose a public
logger class, sink registry, provider collection, or generic service bag:

```matlab
callbackContext.log( ...
    "info", "analysis.completed", ...
    "Analysis completed for 12 valid items.", ...
    Category="analysisRun", ...
    Attributes=struct("validItemCount", 12))
```

Optional named inputs are `Category`, `Audience`, `Attributes`, and
`Exception`. The context supplies App/session/operation identity. It validates
severity, applies privacy-safe attribute limits, and never lets a logging sink
failure change the scientific operation outcome.

Apps log domain meaning only: accepted inputs, scientific branch selection,
meaningful counts, completion, degradation, and export. Runtime logs callback
dispatch, presentation, project transactions, source/dialog/result/resource
mechanics, interaction dispatch, rollback, and exception conversion. Pure
scientific functions do not receive a logger; they return results, diagnostics,
or typed failures for the callback boundary to record.

The App-provided `message` is not a place to concatenate a path or filename.
For example, log `"Selected source loaded."` with a Runtime-owned
`sourceAlias`, not `"Loaded " + filepath`. Runtime source mechanics create
session-local aliases such as `source-3`; Apps do not invent redaction. A
selected full path needed by the current workflow is rendered from current App
state and does not pass through the semantic log event.

Project/save/load transactions emit start, validation, commit or rollback, and
one final outcome under one operation ID. A caught exception cannot produce a
misleading success record. Failure presentation and diagnostic recording share
the same correlation ID.

### Framework-owned Log viewer

Replace the 21 App-authored `layout.logPanel` declarations with one standard
Runtime viewer so behavior cannot drift by App. The compact view has columns
**Time | Level | Area | Message**, severity counts, search, follow/pause, and
filters for level, audience, category, and root user action.

Selecting a row reveals safe structured attributes, operation ancestry,
duration/outcome, source location when available, and exception details.
Warnings and errors expose copy/export actions. The viewer visibly reports
when `TRACE` was disabled, older segments expired, repeated records were
coalesced, or records were dropped.

The default projection is user-audience `INFO` and above plus all
`WARNING`-and-higher records. The status panel remains a current-state summary;
it is no longer the implicit “last log line.” Viewer updates are incremental
and virtualized/batched rather than repeatedly joining the full session history.

### Always-on journal, projections, sinks, and retention

A semantic action first becomes one validated privacy-safe event. Internal
projections then feed independent sinks:

1. an in-memory ring for immediate viewer updates;
2. a persistent projection for the bounded segmented JSON Lines flight
   recorder;
3. the App viewer projection;
4. MATLAB command-window output when explicitly enabled for development;
5. an export projection that adds derived interoperability fields and
   human-readable text without reintroducing private values.

Changing one sink's threshold does not change another sink. Formatting happens
after filtering, and an unavailable sink is isolated and reported through the
remaining sinks when possible.

The user-owned journal location is:

```text
<MATLAB prefdir>/LabKit/logs/sessions/<sessionId>/
```

It is not stored in the repository, installation tree, current working
directory, or beside user data. A source checkout may offer a convenience link
to that location, but `artifacts/` is not the product persistence contract.
The Runtime manifest records only canonical Runtime session facts. Repair does
not create a session folder when no App can be resolved. Tests inject a private
temporary Runtime store.

Initial implementation bounds, to be confirmed by profiling before the
contract is frozen, are:

- rotate a JSONL segment at 10 MiB;
- retain at most five segments for the active session;
- retain at most ten closed sessions per App;
- expire closed sessions after 14 days;
- cap retained storage at 50 MiB per App, deleting oldest closed sessions first;
- enforce a profiled per-session bound and a global LabKit bound in addition to
  the per-App bound;
- coalesce repeated identical `TRACE`/`DEBUG` records in a bounded window and
  emit a summary with the suppressed count;
- never rate-limit or coalesce distinct `ERROR`/`CRITICAL` records;
- emit `journal.records_dropped` with count, reason, category, and interval
  whenever capacity, rate limiting, or serialization rejects evidence.

The concrete byte/count values above are profiling hypotheses, not frozen
schema v1 guarantees. Pruning removes expired and oldest closed sessions first,
never the active session, while satisfying session, App, and global bounds.

The writer keeps one active segment handle and a small bounded buffer. It
flushes at measured record/byte thresholds; before and after
`WARNING`/`ERROR`/`CRITICAL`; at selected operation terminal points; and on
close or rotation. Flushing an error also flushes its preceding buffered
context. It does not open and close the JSONL file for every record.

Instrumentation records root actions, operation boundaries, meaningful branch
decisions, and settled interaction state. It does not record every pointer
move, renderer property assignment, or repeated preview setter. Bounded
coalescing handles repetitive `DEBUG`; only opt-in `TRACE` may contain
fine-grained steps.

Normal shutdown closes and flushes the manifest. An active-operation marker and
atomic manifest replacement allow the next launch to identify an abandoned
session. Journal cleanup occurs outside a user callback's critical path.
Failure to create, rotate, flush, or prune a journal never prevents the App
from starting or completing scientific work. Such failures increment explicit
drop/degradation accounting visible through any surviving sink; a broad catch
that silently changes only an internal counter is insufficient.

### Privacy and diagnostic bundles

The live App UI may render a user-selected path directly from current App state
when the workflow requires it. That value does not enter the logging pipeline.
The semantic event accepted by the recorder is already persistence-safe:

```text
App/Runtime meaning
    -> validated privacy-safe semantic event
        |- default Log-viewer projection
        |- persistent journal projection
        `- export/interoperability projection
```

`eventName`, `category`, safe attributes, and operation lineage carry durable
meaning. The human message passes the same sanitizer and privacy validation
before entering the retained in-memory ring or any disk sink. Runtime replaces
source paths, filenames, and identifiers with stable session aliases; Apps do
not perform their own redaction.

Persistent and exported projections redact home, temporary, artifact,
shared-drive, and user-selected roots as a defense in depth; replace filenames
with stable session aliases; and exclude by default:

- project/source contents, images, numeric arrays, tables, and workspace values;
- subject, user, device, sample, and proprietary identifiers;
- original filenames and full local/network paths;
- source-file timestamps and arbitrary metadata copied from input files.

Safe diagnostic facts include component versions, semantic role aliases,
dimensions, counts, selected enum/options, units, validation outcomes,
durations, exception identifiers, and repository-owned source locations.
Free-form App attributes pass through a deny-by-default type/size filter.

**Export Diagnostic Bundle** creates a ZIP only after an explicit user action:

```text
README.txt
manifest.json
events.jsonl
session.log.txt
errors.json
redaction-report.json
```

`README.txt` explains capture bounds and missing intervals. The redaction report
lists categories of removed data, never the removed values. Export snapshots
the already-sanitized journal; export-time scanning is an additional guard, not
the first privacy boundary. Synthetic packs, projects, scientific
inputs/results, screenshots, and source files are not included by default.
LabKit does not upload, email, or transmit a bundle and does not add telemetry
or analytics through this migration.

### Unified launch and synthetic-input workflow

The rescue entry and installed Launcher have different responsibilities. The
rescue entry only checks whether the installed Launcher can be called, performs
the unique ZIP repair transaction when it cannot, and preserves structural load
errors in its repair prompt. It neither discovers Apps nor writes diagnostics.

The installed Launcher is an entrypoint composition owner. It lists/routs Apps
and invokes independent maintenance tools, but does not duplicate their
implementations. After SDK loading, Launcher actions and direct App entrypoints
use the same canonical Runtime session/operation contract. Runtime may create
or associate a normal session at the appropriate action boundary; this ledger
does not freeze a repair handoff or an early-startup lineage shape.

The Runtime lease remains a persistence safety contract: active-session
recovery may abandon only a proven stale same-host process, and must retain
remote, live, malformed, or otherwise uncertain sessions without pruning them.

Rename the misleading `BuildDebugSample` contract to
`BuildSyntheticSample`, and App-owned `+debug` fixture packages to
`+syntheticInputs`. **Generate Synthetic Inputs** validates and writes an
explicit pack/folder chosen by the user, then logs the outcome. It does not
load that pack, reconstruct state, run callbacks, or change the current
project. Sample generation is available in ordinary launches and has no effect
on journal level.

Launcher removes its verbose-plus-sample `Open Debug` branch and
repository-specific diagnostics folder. The standard Runtime Tools menu owns
diagnostics after normal startup; rescue remains a repair affordance, not a
second diagnostic product.

### Compatibility retirement

This is a coordinated App SDK major migration. Temporary bridges exist only to
keep phases reviewable; the final architecture does not retain two logging
models.

| Existing surface | Temporary mapping |
| --- | --- |
| `appendStatus(message)` | `INFO`, `Audience="user"`, event `legacy.status` |
| `reportError(exception)` | correlated `ERROR` with sanitized exception |
| diagnostic `checkpoint` | `DEBUG` structured event |
| diagnostic `count` | `DEBUG` structured event with numeric attribute |
| `StatusLog` | derived viewer projection during migration |
| `DiagnosticRecorder` | adapter into the canonical record/store |
| diagnostic `Options.Level` | bridge to capture/detail policy, not launch mode |

Synthetic input callers are updated explicitly; a legacy sample option is
never silently reinterpreted as a log option. After all callers migrate, delete:

- `appendStatus`, `reportError`, `StatusLog`, the parallel Runtime diagnostics
  row, and the old `DiagnosticRecorder` schema;
- diagnostic options that couple sample construction, persistence, and detail;
- `BuildDebugSample`, App `+debug` packages, and Launcher **Open Debug**;
- App-authored standard `logPanel` declarations and the public layout primitive
  if no intentional nonstandard consumer remains;
- obsolete documentation, examples, tests, and compatibility branches.

No permanent `Intentional compatibility` exemption is accepted for these
surfaces. A genuine saved-project migration remains a versioned persistence
contract; it must not be confused with keeping duplicate logging APIs.

### Implementation sequence and checkpoints

Each phase is a small logical branch checkpoint with focused tests and a prompt
push. Intermediate branch commits do not independently accumulate App release
semantics; versions, manuals, and structured history describe the final net
change before merge.

#### Phase 1: characterize and freeze the minimal contracts

- Add direct characterization tests for current status/error/recorder behavior,
  clean Launcher/direct startup, synthetic sample generation, sanitization, and
  abandoned sessions.
- Specify only the minimal Runtime event schema, severity/audience meanings,
  privacy classification, operation state machine, and manifest ownership.
- Specify retention dimensions and pruning order without freezing byte/count
  hypotheses before measurement.
- Measure normal App startup, callback dispatch, representative interaction,
  viewer update, and recorder throughput/memory.

Exit gate: every known current gap has a failing target test or a documented
manual-only acceptance check; the self-contained Launcher boundary has an
explicit compatibility test; baseline performance artifacts are recorded.

Phase 1 records the automated, non-interactive baselines for normal App
startup, one callback dispatch, and recorder throughput/memory. The following
manual-only evidence is a deferred gate, not a substitute for automation: using
synthetic inputs, capture a native managed-interaction baseline **before Phase
5 first changes interaction behavior**, and capture the legacy
status/log-panel/viewer baseline **before Phase 6 first replaces that viewer**.
Record the host MATLAB release, scenario, and whether any measured interval
includes human wait time. Repeat both manual checks during final manual
acceptance. Do not use a `-batch` GUI run as a substitute for either check.

#### Phase 2: private in-memory canonical stream

- Implement the private event record, validator, session context, operation
  scope/state machine, and bounded in-memory ring.
- Extend sealed `CallbackContext` with the smallest `log` operation justified by
  repeated App need.
- Adapt legacy status/error/checkpoint/count calls into the stream without
  deleting their callers yet.
- Prove one callback produces one complete operation chain and rollback produces
  one terminal failure without a false-success record.

Do not implement the segmented writer, Launcher import, full viewer, or
all-App migration in this checkpoint.

Exit gate: the in-memory stream, privacy validation, operation ancestry, legacy
adapters, and sink-failure isolation pass focused headless evidence.

#### Phase 3: persistence and privacy projections

- Implement the persistent projection, session manifest, segmented buffered
  writer, session/App/global retention, rotation, coalescing, explicit drop
  accounting, and abandoned-operation marker.
- Generate all session identities through one private owner that does not read
  or advance MATLAB's global random-number state. Prove unchanged `rng` state
  for direct stream, default journal, and default Runtime construction paths.
- Replace the scalar terminal outcome model everywhere with orthogonal
  `operationResult` and `stateDisposition` fields. A failed callback whose
  state is restored records `failed` plus `rolledBack` and one `.failed`
  terminal event; no live reader accepts both scalar and structured aliases.
- Implement safe bundle snapshot/export from the already-sanitized journal.
- Enforce the deny-by-default attribute contract, including semantic sensitive
  key rejection plus nesting and serialized-byte bounds.
- Surface journal unavailability and dropped-record degradation in the
  surviving in-memory stream through a non-recursive path that never projects
  the health event back into the failed sink.
- Prove buffered context is flushed with warnings/errors and journal failure
  cannot change the scientific operation outcome.

Exit gate: an ordinary headless session retains bounded, sanitized,
correlation-complete evidence after failure or interruption, with measured
throughput and no per-record open/close path. Session creation does not change
MATLAB RNG state; operation result and state disposition are reconstructable;
sensitive attributes never reach a sink; degradation is visible without
recursion; and every test Runtime injects an explicit temporary journal.

#### Phase 4: repair-only Launcher delegation

- Keep `labkit_launcher.m` self-contained and narrow: boot-critical installed
  entry existence/callability, clear repair errors, and the one GitHub ZIP
  repair transaction. Do not add a journal, schema, session importer, or App
  catalog to it.
- Move installed UI composition and catalog routing to a focused hidden
  `labkit.app.internal.launcher` capability. Menus call independently owned
  tools through their stable entries; Launcher-only glue remains internal.
- Detect incomplete installation lazily: structural installed-entry, dependency,
  or App-startup load failures retain their concrete cause and offer repair;
  scientific input and ordinary user-operation failures do not.
- Validate a ZIP candidate only as a LabKit root with root launcher, installed
  entry, and expected `apps`/`+labkit` content before replacement. Do not add a
  new install manifest, hash, or file inventory.
- Root repair defaults to a trusted latest stable release, with a documented
  stable-tag fallback. It does not retain main-branch selection or a product
  version browser; an independently useful deployment tool may offer deliberate
  version selection while invoking this same root transaction.
- Preserve the Runtime active-session lease contract from Phase 3. Archive
  recovery may abandon only proven stale same-host sessions; live, remote,
  malformed, and uncertain sessions remain visible and unpruned. This is not a
  Launcher lease or inspection algorithm.
- After installed SDK loading, Launcher actions use the normal canonical Runtime
  stream/operation contract. Do not freeze a repair-to-Runtime handoff shape.

Exit gate: a single surviving root launcher can repair missing/damaged
`+labkit`; a healthy install delegates to the installed entry; an invalid ZIP
candidate is rejected; no-network repair failure is actionable; and no root
repair path imports `labkit.*` or creates a journal. Runtime archive tests prove
that a second live MATLAB process cannot be abandoned or pruned.

#### Phase 5: complete Runtime automatic instrumentation

- Instrument lifecycle, callbacks, presentation, projects, sources, dialogs,
  results, resources, managed interactions, rollback, and recovery at semantic
  operation boundaries.
- Exclude pointer-move and renderer-setter noise and prove repetitive debug
  events are bounded.
- Correct framework documentation so every automatic claim has executable
  proof.

Exit gate: the framework fixture App proves every documented Runtime category
and one root action can be reconstructed across nested operations.

#### Phase 6: standard viewer and diagnostic tools

- Build the incremental framework Log viewer, **Tools > Diagnostics** actions,
  problem summary, clear-view semantics, and bundle export.
- Add visible truncation, coalescing, retention, trace-disabled, and dropped
  record state.
- Validate keyboard navigation, screen scaling, long messages, large journals,
  and absence of viewport/callback interference.

Exit gate: an ordinary hidden-GUI session can generate an incident, inspect
earlier `DEBUG` evidence, filter one root action, and export a privacy-safe
bundle without restarting.

#### Phase 7: synthetic inputs and App-family migration

- Rename `BuildDebugSample` and App `+debug` contracts separately from logging
  mechanics; add **Tools > Developer Tools** generation without automatic load.
- Migrate one capability family at a time from status strings to stable domain
  events and safe attributes.
- Remove App-authored log panels and duplicate exception/status presentation
  only after the standard viewer is proven.
- Keep real callback/pointer regressions where interaction is a product
  capability; construction-only evidence is insufficient.

Exit gate: all Apps pass parameterized conformance, each capability family has a
representative real workflow, and no undeclared compatibility use remains.

#### Phase 8: retire bridges and close debt

- Remove **Open Debug**, old APIs/schema, `BuildDebugSample`, `+debug`
  packages, dual options, and bridge-only tests.
- Update current framework/App/Launcher manuals and generated documentation.
- Apply the final cross-component version audit and write one structured history
  record describing the net behavior and compatibility impact.
- Run branch-review validation, developer-led manual acceptance, and final
  sensitive-data/diff audit.

Exit gate: only one supported launch/logging architecture remains and every
completion criterion below is satisfied.

### Required automated evidence

One framework fixture App owns complete headless evidence for:

- severity validation and deterministic derived OpenTelemetry numeric mapping;
- deterministic sequence/time ordering and stable event/attribute schema;
- parent/root operation correlation across success, caught failure, rollback,
  nested callback, and abandoned operation;
- `ERROR` exception capture without duplicate or false-success records;
- sanitization of roots, filenames, identifiers, metadata, exception messages,
  and stacks;
- attribute type/size rejection and safe summarization;
- segment rotation, age/count/byte pruning, active-session preservation,
  repeated-record coalescing, and explicit drop counts;
- atomic manifest/active-operation recovery after interrupted writes;
- sink failure isolation, including unwritable storage and malformed records;
- export bundle file set, schema, ordering, required semantic events, readable
  rendering, and absence of excluded scientific/user data without freezing the
  complete `session.log.txt` wording;
- legacy adapter equivalence during migration and zero adapter use before
  deletion.

Hidden-GUI tests must prove:

- default level/audience projection and live level changes without data loss;
- search, severity/category/root-action filters, follow/pause, clear-view, and
  row-detail rendering;
- warning/error visibility, correlation ID, and export actions;
- large-journal incremental updates without rebuilding the full text control;
- **Tools > Developer Tools** synthetic generation leaves App state and current
  inputs unchanged.

Launcher/system tests must prove that the root file repairs missing/damaged
`+labkit`, a healthy root delegates to the installed entry, an invalid ZIP
candidate is rejected before replacement, and a no-network repair failure is
actionable. They must distinguish structural load/dependency failure (repair
affordance) from ordinary App scientific/input failure, prove no automatic
synthetic behavior, and prove the repair file imports no `labkit.*` symbol or
creates a journal.

All Apps share parameterized conformance proving the standard viewer/tools are
available, no legacy logging API remains, definition/synthetic-input contracts
are legal, and at least one stable domain event is declared. This conformance
does not repeat full journal failure/export workflows per App.

Each capability family selects a representative App for one real hidden-GUI
workflow. Apps with an actual interaction or logging regression retain their
focused callback/pointer test. The framework fixture, not every production App,
systematically covers callback, project, source, dialog, result, resource,
interaction, presentation, rollback, journal, export, and viewer failures.

Performance/capacity tests profile the implementation rather than bless
untested constants. The initial acceptance target is under five percent median
overhead for representative startup and ordinary callbacks with `TRACE` off,
no observable scientific-output change, bounded memory/disk use, and no
quadratic viewer rebuild through at least 10,000 retained records. Any relaxed
threshold needs measured platform evidence and rationale.

Repository data-hygiene tests scan source, tests, fixtures, and exported bundle
schema fixtures for local roots, real filenames, users, subjects, devices,
proprietary metadata, and recognizable sample values. Golden evidence asserts
semantic structure and exclusions, not full message prose.

### Manual acceptance

On at least one representative App from every capability family:

1. launch normally and confirm there is no automatic data or action;
2. complete a normal workflow and judge `INFO` rows for usefulness/noise;
3. trigger a recoverable warning and a controlled callback/transaction failure;
4. reveal prior `DEBUG` history after the failure and follow one root action
   through its nested operations;
5. export a bundle, inspect its readable timeline and redaction report, and
   search it for identifying/local/scientific data;
6. generate synthetic inputs and confirm current App state is unchanged;
7. terminate a session mid-operation and export its recovered journal through
   the next normal Runtime/archive inspection;
8. verify viewer scaling, keyboard use, copy actions, follow/pause, and long
   messages on supported platforms.

Native dialogs, pointer feel, perceived log usefulness, privacy judgment, and
abrupt process termination are not considered proven by hidden GUI tests.

### Completion and ledger removal

The migration is complete only when:

- repair is a self-contained, journal-free rescue entry; healthy installed
  Launcher and direct App paths use the canonical Runtime contract only after
  SDK loading;
- ordinary sessions have a bounded, always-on, privacy-safe flight recorder;
- severity, audience, category, event, operation scope, and sink thresholds
  have one canonical contract;
- all documented automatic Runtime categories have executable evidence;
- every public App uses the standard viewer/tools and domain logging contract;
- synthetic inputs are explicit, state-neutral, and independent of logging;
- incident export works for current and Runtime-recovered abandoned sessions;
- old status/diagnostic/debug surfaces and every temporary bridge are deleted;
- per-session, per-App, and global retention plus degradation, privacy,
  performance, automated, and manual acceptance gates pass;
- current manuals, versions, generated docs, and one final cross-component
  structured history record describe the supported net behavior.

Delete this active entry in the final zero-debt squash change. Preserve durable
behavior and rationale in the owning manuals and structured component history;
do not create a future-state migration page under `docs/`.

## Maintaining the ledger

Open an entry only for a concrete current problem with an owner, observable
effect, focused test, completion criteria, and removal condition. Do not copy a
completed audit, supported behavior inventory, speculative cleanup, file-size
concern, or possible future abstraction into this file.

Temporary MathWorks Toolbox use must record the exact source symbol, product,
owner, repository fallback, fallback test, idempotency evidence, numeric parity
outputs and tolerance, and the condition for deleting the Toolbox branch. Its
machine-readable declaration lives in `tests/+labkittest/toolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history.
