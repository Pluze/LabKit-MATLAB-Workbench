# LabKit Core Apps

Core apps provide cross-domain tools that are useful to many LabKit workflows
but do not own a scientific measurement or experiment-specific formula.

## Choose An App

| Task | App |
| --- | --- |
| Restyle a MATLAB figure and export its visible graphics | [Figure Studio](figure-studio/README.md) |

## Figure Handoff

Figure Studio can open tracked `.fig` files or receive a plot sent from a
LabKit plot context menu. The lightweight framework popout is intended for
inspection; Figure Studio is the durable workflow for controlled canvas and
style settings, raster/vector export, and a data-plus-recreation-script
package.

Figure Studio snapshots visible graphics. It does not rerun the calculation
that produced the original figure and does not claim that displayed graphics
are a lossless replacement for the original scientific dataset.

## Related Documentation

- [Figure Studio manual](figure-studio/README.md)
- [App Framework](../../framework/README.md)
- [Architecture](../../development/architecture.md)
