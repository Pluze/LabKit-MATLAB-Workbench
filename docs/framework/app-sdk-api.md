# App SDK API

Use this page to move from the App Framework concepts to exact MATLAB
contracts. These links stay within the Framework reading path; each function
page provides syntax, inputs, outputs, options, errors, and related APIs.

## Start With The Core Contract

- [Definition](../reference/api/labkit/app/Definition.html) declares an App.
- [layout](../reference/api/labkit/app/layout/workbench.html) assembles the
  semantic workbench.
- [Snapshot](../reference/api/labkit/app/view/Snapshot.html) presents derived
  visible state.
- [CallbackContext](../reference/api/labkit/app/CallbackContext.html) exposes
  runtime capabilities to callbacks.

## Browse By Capability

| Capability | API entry point |
| --- | --- |
| Layout and controls | [App SDK layout API](../reference/api/labkit/app/layout/workbench.html) |
| View snapshots | [App SDK view API](../reference/api/labkit/app/view/Snapshot.html) |
| Typed events | [App SDK event API](../reference/api/labkit/app/event/ListSelection.html) |
| Projects and sources | [App SDK project API](../reference/api/labkit/app/project/Schema.html) |
| Results | [App SDK result API](../reference/api/labkit/app/result/File.html) |
| Managed interactions | [App SDK interaction API](../reference/api/labkit/app/interaction/anchorPath.html) |
| Plot mechanics | [App SDK plot API](../reference/api/labkit/app/plot/clearAxes.html) |
| Runtime diagnostics | [Runtime diagnostics and session logging](guides/runtime.md#diagnostics-and-session-logging) |
| Dialog results | [App SDK dialog API](../reference/api/labkit/app/dialog/Choice.html) |

## Related Topics

- [App Framework](README.md)
- [Runtime and Lifecycle](guides/runtime.md)
- [Build a Complete App](../development/build-apps/complete-app.md)
