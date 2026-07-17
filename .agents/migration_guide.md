# Migration Debt And Maturity Plan

This file is the active execution ledger for architecture migration debt.
Current supported behavior belongs in `docs/`; exact validation commands belong
in `docs/development/testing.md`; completed work belongs in component history.
Do not describe a migration area as complete while an accepted public or
private App still relies on the retired contract.

## Working order

Work in two gated stages:

1. reproduce and close every concrete defect in this ledger;
2. only after the closure gate passes, measure the stable system and make
   evidence-backed maturity improvements.

Do not mix speculative simplification into defect fixes. Each coherent repair
owns its regression test, documentation or agent-rule correction when needed,
version/history update when required by project policy, and a small independent
commit. Public and private repositories commit and push their work separately.

## Active debt

Last audited: 2026-07-17.

```text
documentation-and-agent-contract-drift: open-high
validation-isolation-coverage: open-high
toolbox-product-debt: none
```

### Documentation and agent contract drift

Owner:
: The owning manuals, public MATLAB help, agent skills/rules, and documentation
  contract tests.

Evidence:
: The public-help guard checks section presence and at least one option but
  does not prove every option, default, legal value, error, or related API is
  documented. Its module scan omits the rendered public
  `labkit.ui.version` page.

Affected scope:
: Current development/framework/private-App manuals, public help, relevant
  skills and scoped rules, documentation renderer inputs, generated `site/`,
  and documentation tests.

Completion condition:
: Current manuals and agent instructions name one owner for canonical
  validation and definition metadata, describe only existing APIs, and agree
  with real public/private App structure. Every public API participates in the
  help contract. Struct options are all explained with defaults and legal
  values; errors or an explicit no-error contract and related APIs are present;
  executable examples run in a clean owning path.

Focused validation:
: Run the narrow documentation contract and renderer regression tests while
  editing, regenerate `site/` only through `renderLabKitDocs`, run `docsCheck`,
  verify links/search, and visually inspect representative changed pages when
  rendered structure changes.

Removal condition:
: Delete this entry after source help, authored manuals, agent instructions,
  generated pages, and focused tests agree. Do not claim semantic accuracy from
  a successful byte-for-byte documentation build alone.

### Validation isolation coverage

Owner:
: Project test architecture and the private repository's own test runner.

Evidence:
: The public test setup adds all public App roots, which can hide sibling-App
  dependencies. Public architecture and facade compatibility discovery covers
  public `apps/` but does not give an accepted independent private repository
  an equivalent launch-contract check. Hidden GUI tests remain intentionally
  unable to prove native dialogs, pointer feel, visual quality, real data, or
  scientific validity.

Affected scope:
: App boundary tests, debug-sample coverage, private compatibility tests,
  changed-file routing, and CI scope.

Completion condition:
: Fast isolated-path tests protect App metadata, debug samples, and package
  independence; the private repository checks its own facade compatibility;
  test documentation continues to state manual limits honestly. Evaluate a
  measured changed-App GUI smoke lane for ordinary CI without moving the full
  GUI suite out of scheduled/manual/release validation unless runtime evidence
  justifies it.

Focused validation:
: Run new isolation tests alone, then their owning contract suites. At the
  stable closure checkpoint run `buildtool changed`; reserve full GUI and
  release gates for the scopes defined in the testing manual.

Removal condition:
: Delete this entry when the known masking behavior has a regression test,
  private compatibility is protected in its owning repository, routing selects
  the new tests, and CI cost has been measured rather than guessed.

## Intentional compatibility

Read-only saved-data compatibility is not automatically migration debt.
Retain it when a current user file needs it and the current writer always emits
the current format:

- Video Marker imports its declared legacy project variable and writes the
  current `labkitProject` envelope.
- Current App project specs migrate supported older payload versions through
  one version-aware `Migrate` entry.
- `labkit.dta` retains documented legacy field aliases beside canonical,
  unit-explicit fields until a future major-version decision.

Do not use a saved-data promise to justify old source layouts, launch
factories, migration callback collections, or undocumented UI nodes.

## Defect closure gate

Do not begin general architecture simplification until all of these are true:

- the accepted private Imager App is UI 7 compatible and independently tested;
- Gait debug generation works in a launcher-equivalent isolated path;
- no App production or debug package calls a sibling App package;
- missing, cancelled, damaged, and unsupported project sources have distinct,
  tested outcomes and no broad exception is silently swallowed;
- current manuals, public help, skills, tests, and generated pages describe the
  same contract;
- focused suites pass, one stable `buildtool changed` gate passes, both Git
  worktrees are clean, and coherent commits are pushed to their own remotes.

## Maturity work after closure

After the closure gate, remeasure the stable code before opening new work.
Apply these rules rather than pursuing raw file or line-count reduction.

### Progressive App capability

A static App needs only its entrypoint, definition, and data-only layout. Add
actions, presentation, durable project state, transient session reconstruction,
renderers, interactions, and Start behavior only for a demonstrated product
capability. Remove an optional component only when its owned behavior is truly
absent; do not move the same behavior into an ambiguously named helper.

### Protocols between Apps

Apps exchange versioned files or documented data structures, not implementation
calls. Producer-consumer integration belongs in tests. A shared public facade
is justified only by a domain-neutral contract with two real consumers or a
clear existing-facade owner.

### Runtime stability

Treat Runtime complexity as centralized infrastructure, not proof that it
should become public. Maintain an internal ownership map for definition,
transactions/queueing, persistence/relinking, layout, presentation,
interactions/resources, startup, and diagnostics. Refactor a hotspot only for
a reproduced defect, measured performance problem, duplicated ownership, or
unclear failure boundary.

### Failure model

Classify failures consistently:

- recoverable input problems preserve state and explain the next action;
- cancellation exits without side effects;
- damaged or unsupported data fails explicitly;
- programming errors remain visible to diagnostics and tests;
- App-owned batch policy decides whether one failed row continues or stops;
- Runtime state transactions roll back on failure.

### Performance evidence

Measure startup-to-first-visible, startup-to-first-useful-view, file
registration, selected-file decode, file switching, project restoration,
common callbacks, Run, and Export on bounded small and large synthetic inputs.
Keep selection and first preview lazy when the workflow permits it. Open
performance debt only from a reproducible profile and close it with an
outcome-based regression test or justified budget.

### Documentation as contract

Public help and manuals explain real callable behavior; examples execute;
options, units, assumptions, defaults, legal values, errors, and related APIs
are complete. `site/` remains generated. History records completed evolution,
not planned work. Stable accepted principles update existing architecture,
framework, App-development, or testing manuals rather than creating another
permanent roadmap that can drift.

### Testing and debt governance

Use direct scientific/unit tests, state and file-contract tests, bounded hidden
GUI workflows, isolation/architecture guardrails, and explicit manual checks
for native dialogs, pointer interaction, visual quality, and scientific
validity. Debt requires observable evidence, an owner, a focused test,
completion criteria, and a removal condition. File length, helper count, or a
possible future abstraction is not debt by itself.

## Maintaining this ledger

Open an entry only for a concrete current problem with ownership, behavior,
testability, performance, or cognitive load. Temporary MathWorks Toolbox use
must also record the exact source symbol, product, repository fallback,
fallback test, idempotency evidence, numeric parity outputs and tolerance, and
the condition for deleting the Toolbox branch; its machine-readable declaration
lives in `tests/runner/labkitToolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve the durable decision and evidence in component history when
project policy requires it. Keep this ledger compact again when every concrete
field is genuinely `none`.
