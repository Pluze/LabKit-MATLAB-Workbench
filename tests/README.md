# Test Layout

`run_all_tests.m` owns test ordering. Test files are grouped by the behavior they protect:

```text
helpers/        shared test setup and assertions
suites/core/    startup, architecture boundaries, and templates
suites/dta/     DTA parsing, loading, sessions, pulse detection, and schemas
suites/apps/    app-local analysis, plotting helpers, and exports
suites/gui/     noninteractive GUI launch and layout checks
```

Keep helpers limited to setup and assertions. Do not move app-specific formulas, result schemas, export formats, or expected scientific values into shared helpers.

Default command:

```bash
scripts/run_matlab_tests.sh
```

Optional noninteractive GUI smoke checks can use `scripts/run_matlab_tests.sh --gui` when launch or layout coverage is relevant.

Focused checks can use suite or test filters:

```bash
scripts/run_matlab_tests.sh --suite core
scripts/run_matlab_tests.sh --test test_gui_layout_controls
```
