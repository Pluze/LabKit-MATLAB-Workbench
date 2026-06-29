# Support

Use the launcher and app docs first:

- Normal use starts from the single-file launcher in the root [README](../README.md).
- App commands, inputs, and expected outputs are listed in [docs/apps.md](../docs/apps.md).
- Development and validation commands are listed in [docs/testing.md](../docs/testing.md).

## Report A Problem

Open a bug report when LabKit fails to launch, load data, run an app workflow,
write an export, or pass a documented validation command.

Include:

- the app command or affected file
- how you got LabKit: release, latest launcher update, or git checkout
- MATLAB version and operating system
- short reproduction steps
- the expected and actual behavior
- redacted logs or generated artifact folder names, if available
- for GUI hangs or callback errors, the generated debug log plus any
  `*_crash_report.txt` or `*_active_operation.txt` file. These reports include
  the exact MATLAB error id/message/stack and a recent-operation trace that
  helps reconstruct the repro path.

Do not upload raw lab files, identifying file names, subject names, device
serials, local absolute paths, timestamps, or private experiment labels. Use
synthetic or redacted examples.

## Request A Workflow Change

Open an app workflow request when you need a new import path, export, table,
plot, option, or GUI flow. Describe the workflow in user terms: what files go
in, what the user reviews, and what outputs should be produced.

## Contributing

For source changes, start with [docs/testing.md](../docs/testing.md) and use
the pull request template. Keep app-specific behavior in the owning app unless
the shared `+labkit` foundation clearly owns a domain-neutral contract.
