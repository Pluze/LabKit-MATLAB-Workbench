% App-owned managed-ROI callback. Expected caller: the Batch Crop cropRoi
% interaction. Inputs are application state, a canvas [x y width height]
% position, and callback context. The returned state stores only the moved
% original-image crop center and clears derived export state.
function applicationState = changeCropRectangle( ...
        applicationState, position, callbackContext)
%CHANGECROPRECTANGLE Move the current crop center from a dragged preview ROI.

[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded || ~(isnumeric(position) && numel(position) == 4) || ...
        any(~isfinite(double(position)))
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
item = batch_crop.sourceFiles.currentItem(applicationState);
[geometry, ~] = batch_crop.cropGeometry.currentGeometry( ...
    applicationState.session.cache.canvas, index, item, ...
    batch_crop.cropGeometry.itemPaddingPercent(item, 0));
currentPosition = batch_crop.cropGeometry.cropRectanglePosition( ...
    geometry, item.centerXY, batch_crop.cropGeometry.currentCropSize(applicationState));
canvasCenter = batch_crop.cropGeometry.originalToCanvas(geometry, item.centerXY);
canvasCenter = canvasCenter + double(position(1:2)) - currentPosition(1:2);
center = batch_crop.cropGeometry.canvasToOriginal(geometry, canvasCenter);
applicationState = batch_crop.cropGeometry.setCurrentCenter( ...
    applicationState, center, true);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState);
callbackContext.appendStatus(sprintf( ...
    "Moved crop ROI for task %d: x=%.1f, y=%.1f.", index, ...
    applicationState.project.inputs.items(index).centerXY));
end
