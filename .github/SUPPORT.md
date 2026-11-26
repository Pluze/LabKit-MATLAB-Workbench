# Support

Use the launcher and app docs first:

- Normal use starts from the single-file launcher in the root [README](../README.md).
- App commands, inputs, and expected outputs are listed in the [App catalog](../docs/use/apps/README.md).
- Development and validation commands are listed in [Testing](../docs/develop/testing.md).

## Report A Problem

Open a bug report when LabKit fails to launch, load data, run an app workflow, write an export, or pass a documented validation command.

Include:

- the app command or affected file
- how you got LabKit: release, latest launcher update, or git checkout
- MATLAB version and operating system
- the steps someone else can follow to see the same problem
- what you expected and what happened instead
- if clicking a control produces an error, copy the relevant redacted events from **LabKit ▾ → Diagnostics → Open Session Log...**
- if the App is unresponsive, inspect its saved session under `artifacts/logs/sessions/` and share the relevant redacted entries from `events-*.jsonl`
- for a Launcher startup problem, include the relevant redacted events from **Workbench tools → View Launch Log** when available

Do not upload raw lab files, identifying file names, subject names, device serials, local absolute paths, timestamps, or private experiment labels. Use synthetic or redacted examples.

## Request A Workflow Change

Open an app workflow request when you need a new import path, export, table, plot, option, or GUI flow. Describe the workflow in user terms: what files go in, what the user reviews, and what outputs should be produced.

## Contributing

For source changes, start with [Testing](../docs/develop/testing.md) and use the pull request template. Keep code for one App in that App. Put code in `+labkit` when several Apps need the same behavior.
