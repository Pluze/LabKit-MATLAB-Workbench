% App-owned implementation for batch_crop.cropGeometry.paddingChanged within the batch_crop product workflow.
function applicationState = paddingChanged( ...
        applicationState, value, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
fallback = applicationState.project.inputs.items(index).paddingPercent;
if isnumeric(value) && isscalar(value) && isfinite(double(value))
    fallback = double(value);
end
applicationState.project.inputs.items(index).paddingPercent = ...
    min(max(fallback, 0), 200);
applicationState = batch_crop.cropGeometry.ensureCurrentCenter(applicationState);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState, true);
applicationState.session.view.scaleBar = [];
callbackContext.log("info", "batch_crop.cropgeometry.paddingchanged.status", sprintf( ...
    "Updated padding for crop task %d: %.3g%%.", index, ...
    applicationState.project.inputs.items(index).paddingPercent));
end
