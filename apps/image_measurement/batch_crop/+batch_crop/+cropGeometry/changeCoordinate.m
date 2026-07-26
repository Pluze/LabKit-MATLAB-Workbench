% App-owned implementation for batch_crop.cropGeometry.changeCoordinate within the batch_crop product workflow.
function applicationState = changeCoordinate( ...
        applicationState, value, dimension, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded || ~(isnumeric(value) && isscalar(value) && isfinite(double(value)))
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
center = applicationState.project.inputs.items(index).centerXY;
center(dimension) = double(value);
applicationState = batch_crop.cropGeometry.setCurrentCenter( ...
    applicationState, center, true);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState);
callbackContext.log("info", "batch_crop.cropgeometry.changecoordinate.status", sprintf( ...
    "Set crop center for task %d: x=%.1f, y=%.1f.", index, ...
    applicationState.project.inputs.items(index).centerXY));
end
