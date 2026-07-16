# Figure Studio

Figure Studio restyles existing MATLAB figures and exports their visible
graphics data without changing the calculations that produced them.

## Launch

```matlab
labkit_FigureStudio_app
```

## Workflow

Open a FIG file or choose an existing figure, select axes and graphics objects,
edit presentation properties, and export the revised figure or visible data.
The app is intended for presentation cleanup and inspection, not recomputing
scientific results.

## Behavior

Object selection follows the figure hierarchy. Edits apply to the selected
graphics objects and remain visible in the preview. Data export reads plotted
object data in display order and reports unsupported object types rather than
inventing a table.

## Outputs

- restyled MATLAB figures;
- exported visible line, scatter, image, or surface data where supported;
- recoverable project state for the editing session.

## See Also

- [App Framework](../../api/ui.md)

