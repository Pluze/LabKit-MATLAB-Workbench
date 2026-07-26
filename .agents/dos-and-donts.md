# Working Dos and Don'ts

This file is the repository's compact experience reservoir. After each
meaningful checkpoint, record only a high-value lesson that would save future
investigation, retry, or design cost. Let lessons accumulate and survive
repeated use before promoting them; this is not a chronological work log or a
second architecture guide.

## Record, promote, and compress

- Add only a lesson whose rediscovery would cost meaningful investigation or
  retry time. Record the durable cause and better practice, never a transcript,
  successful command, transient failure, version, or one-off filename.
- Merge with an existing lesson before adding another. Do not promote a new
  observation immediately merely because a destination exists. After it has
  accumulated supporting cases and remained useful over time, promote policy
  to `AGENTS.md`, procedure to a skill, enforceable behavior to a test, or
  product/API meaning to source help or a manual.
- When promotion is proven, merge or remove the reservoir copy. Regularly
  compress related lessons into fewer principle-first statements and delete
  stale, duplicated, disproven, or low-value detail.

## Incubating lessons

### Debug and native presentation

- Debug generates deliberate synthetic inputs without preloading them. Validate
  both the sample contract and a native launch; finite schema placeholders can
  still violate small-image control limits or native presentation.
- Logging severity, capture detail, display filtering, persistence, and
  synthetic-input generation are independent policies. Do not bundle them into
  a Debug launch; an always-on bounded flight recorder is what makes an
  ordinary post-incident session diagnosable.
- A self-contained repair entrypoint owns only minimum health detection,
  repair, and delegation. Do not give it a second log/session schema; canonical
  diagnostics begin after the installed framework is available.
- Make retained semantic events privacy-safe before they enter memory or disk.
  Free-form messages can leak more readily than attributes; export-time
  redaction is defense in depth, not the primary boundary.

### Interaction and previews

- Overlapping gestures need one active owner. A movable ROI must accept its
  visible interior or center as a normal drag target; state geometry alone
  cannot prove pointer ownership.
- Shared image code keeps native pixels by default. Any finite preview budget
  is an explicit App decision, and pixel-unit parameters follow the preview
  scale.

### Validation and compatibility

- Moving behavior to a new owner does not authorize retiring its visible or
  interactive contract. Recreate the old appearance, selection paths, status,
  and failure semantics at the new boundary before deleting the old owner.
- Automatic instrumentation wraps the existing failure boundary, not a wider
  convenience block: preserve specific validation/error identifiers, and test
  nested diagnostic ownership by parent/root ancestry rather than assuming
  every health record attaches directly to the outer callback.
- A destructive updater has one shared write gateway for GUI and programmatic
  callers. Reject invalid roots and both Git-marker forms before network I/O;
  use a sibling backup, preserve explicit local data, validate the replacement,
  and prove success and rollback with path entries that actually existed.
- A changed `projectSpec` needs nonempty owner-level persistence evidence.
  Treat a client timeout during a durable MATLAB run as unknown until its
  progress artifact or terminal log confirms the executor result.
- Treat MATLAB local functions as complete structural blocks. After inserting
  or moving one, inspect the preceding and following `end` boundaries before
  running tests; a misplaced boundary can silently nest later helpers and turn
  a simple edit defect into misleading runtime failures.
- For destructive path checks, compare the resolved existing target with an
  absolute normalized expected path that does not follow links. Canonicalizing
  both sides can hide a redirect, while legacy canonical APIs can miss Windows
  junctions; prove both external and same-root redirects through the public
  operation before allowing recursive deletion.
- After a bulk text rewrite, scan changed MATLAB files for unexpected UTF-8
  BOMs before reviewing semantics. A shell encoding default can otherwise
  create hundreds of noisy first-line changes and conceal the real migration.
- Before starting a durable background MATLAB test run, derive the repository
  root from the runner file, convert suite paths to absolute character cells,
  and assert both the container type and file existence. Reusing this
  preflight prevents repeated no-test runs caused by changed working
  directories or string-cell inputs. For a quick focused run, keep those
  assertions inside MATLAB rather than building a second cross-shell preflight.
- Exact one-way old-data readers are bounded persistence support; simultaneous
  old/new fields on live values are competing models. Defaults cover omitted
  options, while explicit unknown scientific modes fail visibly.
