# LabKit Core Apps

Core apps provide the LabKit workbench entry point and cross-domain tools that
are useful to many workflows but do not own a scientific measurement or
experiment-specific formula.

## Choose An App

| Task | App |
| --- | --- |
| Discover, install, launch, diagnose, and package apps | [LabKit Launcher](launcher/README.md) |
| Restyle a MATLAB figure and export its visible graphics | [Figure Studio](figure-studio/README.md) |

## Workbench Entry Point

The launcher is documented here because users operate it as the first LabKit
application. Its implementation remains a self-contained root file so it can
repair a damaged installation without depending on the app framework.

## Figure Handoff

Figure Studio can open tracked `.fig` files or receive a plot sent from a
LabKit plot context menu. The lightweight framework popout is intended for
inspection; Figure Studio provides the complete workflow for controlled canvas
and style settings, raster/vector export, and a data-plus-recreation-script
package.

Figure Studio snapshots visible graphics. It does not rerun the calculation
that produced the original figure and does not claim that displayed graphics
are a lossless replacement for the original scientific dataset.

## Related Documentation

- [Figure Studio manual](figure-studio/README.md)
- [LabKit Launcher manual](launcher/README.md)
- [App Framework](../../framework/README.md)
- [Architecture](../../development/architecture.md)
