# Working Dos and Don'ts

This is the repository's compact, durable working-memory ledger. Record only a
high-value lesson that will save future agents meaningful investigation, retry,
or design cost. It is not a chronological activity log, a replacement for
architecture manuals, or a place for transient failures.

## Use this file

- After each meaningful work checkpoint, add an entry only when the lesson is
  both reusable and costly to rediscover. Ordinary successful commands,
  routine edits, and one-off observations do not belong here.
- State the durable cause and preferred practice, not a step-by-step transcript
  or a one-off filename.
- Capture failed or wasteful approaches only when the reason and better route
  will prevent a repeated mistake.
- Before adding an entry, merge it into an existing principle whenever
  possible. Periodically compress the document into fewer, principle-first
  rules; remove stale, duplicated, or low-value details instead of accumulating
  a work log.
- Keep product policy in the owning `AGENTS.md`, skill, source help, or manual;
  link or promote a lesson there once it becomes a stable rule.

## Current lessons

### Debug samples

- A diagnostic synthetic sample is a validated, reproducible input fixture;
  it is not permission to preload an App or run startup work. Keep Debug
  launches clean and let users deliberately select generated inputs.
- Test synthetic fixtures twice when practical: validate their project/artifact
  contract and start the App from the fixture in an isolated runtime. A clean
  Debug-start test alone cannot prove the fixture is operational.
- Schema-valid placeholders such as an unset `[NaN NaN]` ROI center are not
  valid synthetic UI data when a native control must render them. Seed every
  interactive sample field with finite, representative values and cover it in
  a hidden-GUI sample-launch test.
- App conformance must launch each App's `BuildDebugSample` project through
  the native adapter as well as validating it headlessly. Clean Debug startup
  proves the diagnostic policy, but only a native sample launch exposes
  control-limit and presentation failures.

### Managed interactions

- A preview axis should have one active editor for overlapping gestures. If a
  workflow needs both a placement click and ROI movement, make them behaviors
  of the same managed interaction instead of relying on editor-focus order.
- State-only geometry tests prove coordinate mapping, not pointer ownership or
  native-control creation. Add hidden-GUI coverage for regressions involving
  native controls, interactions, or dynamic limits.

### Runtime presentation

- When an App narrows a control's dynamic limits, ensure its current bound
  value remains inside those limits before native reconciliation. Test with the
  smallest valid synthetic source, since defaults often exceed small-image
  geometry.

### Validation workflow

- Use `addpath('tests'); labkittest.run(...)` for focused MATLAB validation;
  `buildtool test --tasks` is not a supported selector form.
- Long all-App MATLAB checks can exceed one shell request's timeout. Run them
  as a hidden background MATLAB process with redirected output, then poll the
  log and record the completed result rather than treating a client timeout as
  a test failure.
