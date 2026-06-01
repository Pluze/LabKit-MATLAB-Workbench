# Agent Instructions

This repository provides package-backed MATLAB app entry points and reusable LabKit MATLAB infrastructure for internal lab GUI workflows. It is an app workbench, not a monolithic analysis platform. The reusable core is a small GUI foundation plus current DTA/electrochemistry and biosignal facades; DIC and image-measurement apps are app-level implementations built on the same GUI foundation.

## Read Order

Before editing:

1. `README.md`
2. `AGENTS.md`
3. The source, test, or doc files directly involved in the task

Also read these only when relevant:

- `docs/architecture.md` for package boundaries or entrypoint work
- `docs/ui.md` for reusable GUI shell, components, or layout work
- `docs/dta.md` for DTA API, parser, item, pulse, or session work
- `docs/biosignal.md` for biosignal recording, waveform processing, event/segment, or wearable app work
- `docs/apps.md` for app entrypoints, app-owned workflow, or new app work
- `docs/testing.md` for test or validation work

## Core Rule

Preserve behavior unless the user explicitly asks for a behavior change.

The desired architecture is:

```text
apps/ experiment app category folders
    call reusable +labkit DTA and GUI APIs
    own experiment-specific domain logic, parameters, plots, and exports
    ideally one experiment corresponds to one app .m file

+labkit reusable library
    GUI library: lab-app shells, scrollable/resizable tabs, controls, panels, logs, and UI state helpers
    DTA library: app-facing Gamry DTA discovery, loading, session, pulse, and parsed table/curve APIs
    biosignal library: app-facing physiological/wearable recording loading, waveform processing, event/segment, SNR-style measurement, and group comparison APIs
    internal helpers: parser, analysis, utility, item/session construction, and private helpers hidden behind GUI/DTA APIs
```

Do not add new experiment-specific app logic to the reusable `+labkit` library. New app code should not call `labkit.io.*`, `labkit.data.*`, `labkit.analysis.*`, or `labkit.util.*` directly; put those needs behind `labkit.dta.*`, `labkit.biosignal.*`, `labkit.ui.*`, or an app-local helper. Keep DTA parsers, item/session construction, session IO, and pulse internals private behind the DTA facade. Keep biosignal file normalization private behind the biosignal facade. Keep app-specific analysis, plotting, export schemas, and CSV writing in the owning public app file unless a repeated use case proves a lower-level utility is clearer. Do not reintroduce app-specific helper packages or namespaces just to make local app functions public.

Apps are first-class deliverables and may evolve quickly with real experimental needs. Public `+labkit` API growth should be conservative: extract only domain-neutral, independently testable helpers that are useful beyond one workflow and reduce duplication without increasing API confusion.

Do not change:

- domain formulas, thresholds, integration rules, or result definitions
- parser behavior or pulse detection behavior
- CSV column names or exported table structure
- GUI layout, plot labels, markers, axes, or visual behavior
- current app entrypoint compatibility

Default principle:

```text
same results, cleaner code, clearer boundaries
```

## Allowed Work

- Move duplicated helper logic into `+labkit` package functions only when the helper is genuinely cross-cutting and makes the caller easier to understand.
- Update app entry points to call package helpers when behavior is preserved and the helper boundary matches the GUI or DTA responsibilities above.
- Move app-specific implementations and experiment-specific domain/scientific workflow code out of `+labkit` when doing so preserves behavior.
- Add or update tests for pure functions and app entry points.
- Update documentation to reflect current behavior.
- Improve app entrypoint clarity without reintroducing root-level legacy command wrappers.

## Public API Documentation

Every public library function under `+labkit/+ui`, `+labkit/+dta`, and `+labkit/+biosignal` must document its app-facing call contract in the function comment immediately after the function declaration. Include usage examples when useful, input types, accepted option/spec/label/callback struct fields with defaults and legal values, and output struct/table fields intended for app code. Public facade comments must be sufficient for app authors to call the function without reading private implementations. When options become numerous, provide a default-options helper and recommend starting from it rather than hand-writing hidden struct fields.

Private package functions must also have useful top-of-file comments, but they should describe implementation contracts rather than public API. For every `.m` file under a package `private/` folder, document the expected caller, input and output shapes, important side effects or errors, and any assumptions that are not obvious from the function name. Keep this concise and do not duplicate full public option tables in private helpers.

## Documentation Hygiene

Keep documentation current and concise:

- `README.md` is the human user entry point. Keep it focused on what the project is, how to start apps, current app capabilities, tests, and where to read more. Do not put agent-only rules or historical refactor narration in the README.
- `docs/README.md` is only a documentation map.
- `docs/apps.md` describes current app behavior and ownership boundaries. Do not turn it into a changelog; use compact tables for app-specific notes when possible.
- The repository does not maintain a changelog. Use git history as the durable change record.
- Keep test guidance in `docs/testing.md`; do not add a parallel `tests/README.md`.
- When app controls, exports, or advertised capabilities change, update the README app table and the relevant docs in the same change.
- Avoid duplicating full option schemas in multiple prose docs unless there is a clear user benefit. Prefer one detailed component doc plus public function comments.

## Sensitive Sample Data

Do not introduce sensitive or identifying sample-data details into the repository. This applies to source, tests, docs, comments, commit messages, and generated artifacts.

When using local lab files to reproduce a bug:

- Do not copy raw sample files, local absolute paths, shared-drive paths, filenames, subject/user names, device serials, experiment labels, timestamps, parser-version strings, or other identifying metadata into tracked files.
- Do not preserve proprietary or personally identifying row values merely because they appeared in an example file.
- Use synthetic, minimal fixtures that preserve only the structural format needed for regression coverage, such as preamble rows, header shape, delimiter style, count rows, footer rows, missing values, or time-column behavior.
- Use generic labels such as `DEVICE`, `PrimaryChannel`, `capture start`, and `footer metadata row` instead of real labels from source files.
- Before committing sample-format fixes, search the diff for local paths, original filenames, names, device IDs, timestamps, and other recognizable source-file strings.

## Forbidden Without Explicit Approval

- Do not rewrite all GUIs in one pass.
- Do not replace the current separate app entry points with a single all-in-one launcher without explicit approval.
- Do not reintroduce root-level legacy command wrappers.
- Do not convert struct models to MATLAB classes prematurely.
- Do not migrate code to Python or another language.
- Do not commit generated logs, `.DS_Store`, local experiment output, temporary exports, or unrelated files.

## Tests

Run relevant automated checks after executable MATLAB changes. Use focused checks during scoped iteration instead of defaulting to unrelated app families:

```bash
scripts/run_matlab_tests.sh --suite project
scripts/run_matlab_tests.sh --suite labkit/dta
scripts/run_matlab_tests.sh --suite labkit/dta --suite apps/electrochem
scripts/run_matlab_tests.sh --suite labkit/biosignal
scripts/run_matlab_tests.sh --test test_gui_layout_ui_helpers
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
scripts/run_matlab_tests.sh --suite apps/dic --gui
scripts/run_matlab_tests.sh --suite apps/image_measurement --gui
scripts/run_matlab_tests.sh --suite apps/wearable --gui
scripts/run_matlab_tests.sh --suite apps/electrochem --gui
```

Use the default pure-function suite for broader changes:

```bash
scripts/run_matlab_tests.sh
```

Interactive GUI workflows are checked manually by the user. Use optional noninteractive GUI checks only when GUI launch, layout initialization, callback wiring, or GUI test support changes:

```bash
scripts/run_matlab_tests.sh --gui
```

If MATLAB cannot run, report the blocker and do not claim tests passed.

Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Git Workflow

1. Inspect status before editing.
2. Keep each commit small and logical.
3. Do not mix unrelated functional, documentation, formatting, or test changes.
4. Run relevant tests or explain why they were not run.
5. Review the diff for unrelated changes.
6. Commit with a concise message and, for nontrivial changes, a short body that records intent, API/boundary impact, and validation.
7. Push the completed commit so the remote branch is up to date before handoff.
8. If no files changed, still confirm the local branch is synchronized with its remote before handoff.
9. Do not force-push unless explicitly approved.

Commit messages use a concise Conventional Commits style:

```text
feat: add or change user-facing capability
fix: correct a bug or broken workflow
docs: update documentation only
test: add or update tests only
ci: update GitHub Actions or automation
refactor: restructure code without intended behavior change
chore: maintenance that does not fit the above
```

Use lowercase type prefixes, one imperative summary line, and no trailing period. Prefer one logical concern per commit; if a change mixes source, tests, and docs because they validate the same behavior, keep the summary focused on the behavior. Since git history is the change log, include a compact commit body when the summary alone would not explain why the change was made or how it was verified.

When MATLAB source, tests, fixtures, or package structure change, update the matching current docs:

- `README.md` for user-facing commands or current status
- `docs/architecture.md` for package boundaries or entrypoint roles
- `docs/ui.md` for reusable GUI shell, components, or layout contracts
- `docs/dta.md` for DTA API, parser assumptions, schemas, or sessions
- `docs/biosignal.md` for biosignal facade, signal schemas, event/segment helpers, or wearable boundaries
- `docs/apps.md` for app entrypoints, app-owned workflow, or new app guidance
- `docs/testing.md` for validation coverage

## Handoff

Report:

- changed files
- what was intentionally not changed
- test commands and results
- blockers or unverified behavior
- recommended next step
