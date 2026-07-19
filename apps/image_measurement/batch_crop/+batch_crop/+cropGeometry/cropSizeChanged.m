function applicationState = cropSizeChanged(applicationState, ~, callbackContext)
parameters = applicationState.project.parameters;
parameters.cropWidth = positiveInteger(parameters.cropWidth, 1);
parameters.cropHeight = positiveInteger(parameters.cropHeight, 1);
applicationState.project.parameters = parameters;
applicationState.session.workflow.cropDefaultsInitialized = true;
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if loaded
    applicationState = batch_crop.cropGeometry.ensureCurrentCenter( ...
        applicationState);
end
applicationState = batch_crop.cropGeometry.clearDerived(applicationState);
end

function value = positiveInteger(candidate, fallback)
value = fallback;
if isnumeric(candidate) && isscalar(candidate) && isfinite(double(candidate))
    value = max(1, round(double(candidate)));
end
end
