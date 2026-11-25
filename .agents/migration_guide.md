# Native App interface migration

Continue on `experiment/native-appearance`. The accepted visual reference is the launcher and EIS at `07a0bf8b`. Commit `f86c129c` adds the first navigation pass across the other 24 public Apps and the perspective LK mark. All three references (launcher, EIS, and the mark) are available in Git. A fresh checkout can reproduce the work without the original design files or screenshots.

## Product direction

- Use a light interface. Follow the launcher's continuous tinted left rail, inset rule under the brand, compact header and aligned margins. Use EIS as the working example of the App shell. Keep the LabKit tools menu on the brand button.
- Organize each App around the user's actual task from input to result. Keep workflow steps on the left and result views beside the title. Favor compact, flat navigation and native buttons. Preserve busy feedback and guard repeated submissions. For sliders, distinguish lightweight drag feedback from expensive committed work.
- Preserve scientific plots, plot interactions, units, calculations, data, and export contracts. Exercise representative results before accepting presentation changes. Keep acquisition controls explicit, particularly start and stop.
- Use the shared MATLAB brand mark in the launcher and native Apps. The README and documentation site use the SVG in `tools/docs/assets/`. Verify both representations if the mark changes.
- Keep launcher behavior covered, including the copyable session log, guarded launcher-log viewer, version notes and incremental release loading, and online/local guide selection.

## Resume and acceptance

1. Start with `git show --stat f86c129c` for the changed layouts and tests. The previous host passed all 25 public default-launch checks, codecheck, and docsCheck. The full Apps run was stopped for shutdown. Its partial results and ignored local artifacts are not prerequisites on a new host.
2. Run the full Apps profile from the checkout root in hidden, noninteractive MATLAB. Set `LABKIT_GUI_TEST_MODE=hidden` and `DefaultFigureVisible=off`, then run `addpath('tests'); labkittest.run(Profile="apps")`. Repair observed failures and rerun their exact identities. Complete the profile on the final candidate.
3. Audit each App's actual workflow in its own buildLayout, presenter, manual, and tests. The first pass supplied shared navigation and moved selected primary actions. Individual workflows still need acceptance. Prioritize dense layouts such as FigureStudio, Mark-10 Monitor, Video Marker and ROI Analyzer. Check narrow and wide windows, long labels, button reachability, page switches with loaded data, busy behavior, and continued access to every action. Use hidden exportapp captures for layout and synthetic workflow fixtures for results and exports. Record any pointer, hardware or real-data checks needing human verification.
4. Update the affected manuals to match accepted workflows and reconcile component versions and the structured Change before PR preparation. Keep private App work in its owning repository. Delivery so far is a task-branch push. PR, merge and release are separate operations.

Retire this ledger when the App migration and its acceptance work close.
