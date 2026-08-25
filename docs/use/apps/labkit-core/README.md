# LabKit Core Apps

```labkit-page
id: apps-labkit-core
type: landing
audience: app-user
summary: Core apps provide the LabKit workbench entry point and cross-domain tools that are useful to many workflows but do not own a scientific measurement or experiment-specific formula.
```

Core apps provide the LabKit workbench entry point and cross-domain tools that are useful to many workflows but do not own a scientific measurement or experiment-specific formula.

## Choose An App

| Task | App |
| --- | --- |
| Discover, install, launch, diagnose, and package apps | [LabKit Launcher](launcher/README.md) |
| Restyle a MATLAB figure and export its visible graphics | [Figure Studio](figure-studio/README.md) |

## Workbench Entry Point

The launcher is documented here because it is the first LabKit application most users open. It can also install LabKit or repair a damaged installation.

## Figure Handoff

Figure Studio can open tracked `.fig` files or receive a plot sent from a LabKit plot context menu. The lightweight framework popout is intended for inspection; Figure Studio provides semantic category and object editing, complete axes and tick control, scientific annotations, exact multi-panel layout, publication preflight, raster/vector export, and an editable project package.

A mixed FIG exposes its subplots as editable panels in one document. Studio preserves plotted values while allowing panel, axis, tick, text, style, layer, and annotation edits from whole categories down to one graphic element. It does not rerun the calculation that produced the original figure and does not claim that displayed graphics are a lossless replacement for the original scientific dataset.

## Related Documentation

- [Figure Studio manual](figure-studio/README.md)
- [LabKit Launcher manual](launcher/README.md)
- [App Framework](../../../develop/framework/README.md)
- [Architecture](../../../develop/app-authoring/architecture.md)
