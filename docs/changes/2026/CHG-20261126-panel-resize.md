# Resize panels from a wider grip

```labkit-change
id: CHG-20261126-panel-resize
date: 2026-11-26
type: fix
compatibility: compatible
component: labkit_EIS_app | 1.13.0 -> 1.13.1
component: labkit.app | 3.7.2 -> 3.7.3
component: labkit_ResponseReviewStats_app | 1.9.0 -> 1.9.1
```

## Why

The narrow separator between panels was hard to grab. Pressing away from the edge could also make the sidebar jump at the start of a drag.

## What changed

Row and column dividers now have a 24-pixel drag surface with a one-pixel rule and a short grip. The drag target counts toward the sidebar margin, so the file and navigation buttons align at both ends. The overview actions align with the header action and content edges. The sidebar follows the distance dragged from the initial press. Holding the pointer still at a size limit leaves the grid in place.

Lower and upper range fields have visible labels. Response Review Stats shows that both metric windows use seconds.

Dragging an EIS frequency bound updates raw overview curves in place. Between redraws the slider can accept more movement. Releasing it applies the final value. Group means and uncertainty bars still rebuild from their source observations.

## Impact

Drag the strip between two resizable sections or between the controls and workspace. Selecting the active page again leaves its layout in place.

## Compatibility and limits

The wider strips take up some space between panels. Scientific settings and saved files use the same formats.
