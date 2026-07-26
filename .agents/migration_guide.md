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

1. Every launch creates one session identity and one canonical logging pipeline
   before Launcher resolution or App construction begins.
2. A bounded local flight recorder is always on. It captures sufficient
   structured `DEBUG`-and-higher evidence to diagnose a later failure without
   requiring the user to predict that failure. `TRACE` is opt-in because of its
   potential volume.
3. The App Log viewer shows concise, actionable user information. Its filter
   does not decide what the recorder captured and cannot erase earlier detail.
4. A user can export the retained current-session history after a problem.
   Launcher can also export the most recent abandoned or failed launch.
5. “Complete history” means the retained semantic action chain, state
   transitions, outcomes, durations, warnings, and exceptions. It does not mean
   raw scientific arrays, workspace snapshots, images, or every call frame.
6. Any retention, rate-limit, or sink failure is represented explicitly; the
   system must never pretend a truncated journal is complete.
7. Synthetic inputs are an explicit tool action. Generating them does not
   mutate current App state, load a project, start analysis, or change logging
   policy.

The framework-owned App toolbar provides:

- **Show Logs**
- **Display Level** (`Info`, `Debug`, or `Trace`)
- **Generate Synthetic Inputs**
- **Export Diagnostic Bundle**
- **Copy Problem Summary**
- **Clear Log View**

`Clear Log View` clears only the current viewer projection. It does not silently
delete the flight recorder. `ERROR` leaves the App usable when recovery is
possible and exposes the correlation ID and export action. `CRITICAL` means the
session is not safe for further product actions; diagnostic export remains
available.

Launcher removes **Open Debug**. It uses the same launch pipeline as direct App
entrypoints and provides **Export Last Launch Diagnostics** when startup failed
before the App toolbar became available.

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

The repository owns a versioned record schema. A record contains:

- `schemaVersion`, monotonic `sequence`, `timestampUtc`,
  `observedTimestampUtc`, and relative `elapsedSeconds`;
- `severityText`, OpenTelemetry-compatible `severityNumber`, `audience`,
  `category`, stable `eventName`, human `message`, and bounded `attributes`;
- `appId`, App version, SDK version, MATLAB/platform facts, and `sessionId`;
- `operationId`, `parentOperationId`, and `rootActionId`;
- `outcome`, `durationSeconds`, and optional source function/line;
- for failures, exception identifier, sanitized message, causal chain, and
  sanitized stack.

`message` is readable prose and may evolve. `eventName` and attribute keys are
the machine-stable contract used by tests and diagnostic tooling. Attributes
are scalars, short strings, small categorical arrays, or bounded plain structs.
The recorder rejects or summarizes handles, classes, large arrays, graphics
objects, tables containing sample data, and arbitrary workspace values.

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

### Always-on journal, sinks, and retention

The canonical session stream feeds independent sinks:

1. an in-memory ring for immediate viewer updates;
2. a bounded segmented JSON Lines flight recorder;
3. the App viewer projection;
4. MATLAB command-window output when explicitly enabled for development;
5. an on-demand human-readable text rendering used in exported bundles.

Changing one sink's threshold does not change another sink. Formatting happens
after filtering, and an unavailable sink is isolated and reported through the
remaining sinks when possible.

The user-owned journal location is:

```text
<MATLAB prefdir>/LabKit/logs/<appId>/<sessionId>/
```

It is not stored in the repository, installation tree, current working
directory, or beside user data. A source checkout may offer a convenience link
to that location, but `artifacts/` is not the product persistence contract.
Tests inject a private temporary store.

Initial implementation bounds, to be confirmed by profiling before the
contract is frozen, are:

- rotate a JSONL segment at 10 MiB;
- retain at most five segments for the active session;
- retain at most ten closed sessions per App;
- expire closed sessions after 14 days;
- cap retained storage at 50 MiB per App, deleting oldest closed sessions first;
- coalesce repeated identical `TRACE`/`DEBUG` records in a bounded window and
  emit a summary with the suppressed count;
- never rate-limit or coalesce distinct `ERROR`/`CRITICAL` records;
- emit `journal.records_dropped` with count, reason, category, and interval
  whenever capacity, rate limiting, or serialization rejects evidence.

Normal shutdown closes and flushes the manifest. An active-operation marker and
atomic manifest replacement allow the next launch to identify an abandoned
session. Journal cleanup occurs outside a user callback's critical path.
Failure to create, rotate, flush, or prune a journal never prevents the App
from starting or completing scientific work.

### Privacy and diagnostic bundles

The live App UI may display a user-selected path when the workflow requires it.
Persistent and exported records use a stricter policy. They redact home,
temporary, artifact, shared-drive, and user-selected roots; replace filenames
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
lists categories of removed data, never the removed values. Synthetic packs,
projects, scientific inputs/results, screenshots, and source files are not
included by default. LabKit does not upload, email, or transmit a bundle and
does not add telemetry or analytics through this migration.

### Unified launch and synthetic-input workflow

Launcher and direct entrypoints share one bootstrap:

1. create the session identity and bootstrap recorder;
2. record Launcher/App resolution and requirement checks;
3. create Runtime and transfer the same session/operation lineage;
4. launch a clean App with no project, source, sample, or automatic action;
5. close or mark the session abandoned on every startup outcome.

Direct entrypoints create the same session when no Launcher session is supplied.
Tests inject deterministic clocks, IDs, and private stores; production APIs do
not expose those controls.

Rename the misleading `BuildDebugSample` contract to
`BuildSyntheticSample`, and App-owned `+debug` fixture packages to
`+syntheticInputs`. **Generate Synthetic Inputs** validates and writes an
explicit pack/folder chosen by the user, then logs the outcome. It does not
load that pack, reconstruct state, run callbacks, or change the current
project. Sample generation is available in ordinary launches and has no effect
on journal level.

Launcher removes its verbose-plus-sample `Open Debug` branch and
repository-specific diagnostics folder. It shows the most recent failed or
abandoned launch with actions to copy the problem summary, export its bundle,
and open the session folder.

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

#### Phase 1: characterize and specify

- Add direct characterization tests for current status/error/recorder behavior,
  clean Launcher/direct startup, synthetic sample generation, sanitization, and
  abandoned sessions.
- Define the record schema, severity rules, privacy matrix, event/category
  vocabulary, retention policy, and golden bundle shape as repository-owned
  test data.
- Measure normal App startup, callback dispatch, viewer update, and recorder
  throughput/memory before changing implementation.

Exit gate: every known current gap has a failing target test or a documented
manual-only acceptance check; baseline performance artifacts are recorded.

#### Phase 2: canonical record and flight recorder

- Implement the private canonical record, validator, operation scope, session
  manifest, segmented writer, pruning, rate limiting, drop accounting, and
  sanitization.
- Extend sealed `CallbackContext` with `log`.
- Adapt legacy recorder/status calls into the stream without changing App
  behavior.
- Ensure a recorder failure is contained and observable from another sink.

Exit gate: ordinary headless sessions persist bounded, sanitized,
correlation-complete history and all legacy behavior tests still pass.

#### Phase 3: complete Runtime instrumentation

- Instrument lifecycle, callbacks, presentation, projects, sources, dialogs,
  results, resources, managed interactions, rollback, and recovery.
- Transfer one bootstrap session across Launcher and Runtime.
- Align direct and Launcher entrypoint evidence.
- Correct framework documentation so every automatic claim has executable
  proof.

Exit gate: each documented automatic category has start/success/failure or
explicit non-applicability evidence, and one root action can be reconstructed
across nested operations.

#### Phase 4: standard viewer and diagnostic tools

- Build the incremental framework Log viewer, toolbar actions, last-launch
  recovery, problem summary, and diagnostic bundle export.
- Add visible truncation/coalescing/drop state and clear-view semantics.
- Validate keyboard navigation, screen scaling, long messages, large journals,
  and absence of viewport/callback interference.

Exit gate: an ordinary hidden-GUI session can generate an incident, inspect
earlier `DEBUG` evidence, and export a privacy-safe bundle without restarting.

#### Phase 5: migrate Apps by capability family

- Replace status strings with stable events and domain attributes.
- Remove App-authored log panels and duplicate exception/status presentation.
- Audit each App's warnings, errors, transaction outcomes, exports, long
  operations, synthetic inputs, and direct public entrypoint.
- Run a real callback/pointer workflow where interaction is a declared product
  capability; construction-only tests are insufficient.

Exit gate: every public App passes the shared logging conformance suite plus
its focused user-workflow evidence, with no undeclared compatibility use.

#### Phase 6: unify launch and remove debt

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

Framework headless tests must prove:

- severity validation and OpenTelemetry-compatible numeric mapping;
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
- export bundle contents, ordering, readable rendering, and absence of excluded
  scientific/user data;
- legacy adapter equivalence during migration and zero adapter use before
  deletion.

Hidden-GUI tests must prove:

- standard viewer presence in every migrated App;
- default level/audience projection and live level changes without data loss;
- search, severity/category/root-action filters, follow/pause, clear-view, and
  row-detail rendering;
- warning/error visibility, correlation ID, and export actions;
- large-journal incremental updates without rebuilding the full text control;
- toolbar synthetic generation leaves App state and current inputs unchanged.

Launcher/system tests must prove clean direct and Launcher startup, identical
session handoff, early requirement/build failure capture, last-launch recovery,
and removal of automatic synthetic behavior.

Every App has a cataloged conformance row for ordinary startup, one meaningful
success event, validation/degradation where applicable, one controlled failure,
export, and synthetic-input generation. Apps with managed interactions also
retain their pointer-driven workflow tests so log migration cannot mask a
non-interactive GUI.

Performance/capacity tests profile the implementation rather than bless
untested constants. The initial acceptance target is under five percent median
overhead for representative startup and ordinary callbacks with `TRACE` off,
no observable scientific-output change, bounded memory/disk use, and no
quadratic viewer rebuild through at least 10,000 retained records. Any relaxed
threshold needs measured platform evidence and rationale.

Repository data-hygiene tests scan source, tests, fixtures, and exported golden
bundles for local roots, real filenames, users, subjects, devices, proprietary
metadata, and recognizable sample values.

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
7. terminate a session mid-operation and export it from the next Launcher run;
8. verify viewer scaling, keyboard use, copy actions, follow/pause, and long
   messages on supported platforms.

Native dialogs, pointer feel, perceived log usefulness, privacy judgment, and
abrupt process termination are not considered proven by hidden GUI tests.

### Completion and ledger removal

The migration is complete only when:

- one launch architecture serves Launcher and direct entrypoints;
- ordinary sessions have a bounded, always-on, privacy-safe flight recorder;
- severity, audience, category, event, operation scope, and sink thresholds
  have one canonical contract;
- all documented automatic Runtime categories have executable evidence;
- every public App uses the standard viewer/tools and domain logging contract;
- synthetic inputs are explicit, state-neutral, and independent of logging;
- incident export works for current, startup-failed, and abandoned sessions;
- old status/diagnostic/debug surfaces and every temporary bridge are deleted;
- retention, degradation, privacy, capacity, performance, automated, and manual
  acceptance gates pass;
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
