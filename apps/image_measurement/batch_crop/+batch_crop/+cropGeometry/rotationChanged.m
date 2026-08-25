% App-owned implementation for batch_crop.cropGeometry.rotationChanged within the batch_crop product workflow.
function applicationState = rotationChanged( ...
        applicationState, value, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
fallback = applicationState.project.inputs.items(index).angleDeg;
applicationState.project.inputs.items(index).angleDeg = ...
    finiteScalar(value, fallback);
applicationState = batch_crop.cropGeometry.ensureCurrentCenter(applicationState);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState, true);
applicationState.session.view.scaleBar = [];
end

function value = finiteScalar(candidate, fallback)
value = fallback;
if isnumeric(candidate) && isscalar(candidate) && isfinite(double(candidate))
    value = double(candidate);
end
end
