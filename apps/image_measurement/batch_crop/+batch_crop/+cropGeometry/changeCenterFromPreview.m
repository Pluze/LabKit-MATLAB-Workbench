% App-owned implementation for batch_crop.cropGeometry.changeCenterFromPreview within the batch_crop product workflow.
function applicationState = changeCenterFromPreview( ...
        applicationState, value, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded
    return
end
if isstruct(value) && isfield(value, "points") && ...
        ~isempty(value.points) && size(value.points, 2) == 2
    point = double(value.points(1, :));
elseif isnumeric(value) && numel(value) == 2 && ...
        all(isfinite(double(value)))
    point = double(reshape(value, 1, []));
else
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
item = batch_crop.sourceFiles.currentItem(applicationState);
[geometry, ~] = batch_crop.cropGeometry.currentGeometry( ...
    applicationState.session.cache.canvas, index, item, ...
    batch_crop.cropGeometry.itemPaddingPercent(item, 0));
center = batch_crop.cropGeometry.canvasToOriginal(geometry, point);
applicationState = batch_crop.cropGeometry.setCurrentCenter( ...
    applicationState, center, true);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState);
callbackContext.appendStatus(sprintf( ...
    "Placed crop center for task %d: x=%.1f, y=%.1f.", index, ...
    applicationState.project.inputs.items(index).centerXY));
end
