% App-owned implementation for batch_crop.scaleCalibration.settingsChanged within the batch_crop product workflow.
function applicationState = settingsChanged(applicationState, ~, ~)
parameters = applicationState.project.parameters;
parameters.physicalWidth = positive(parameters.physicalWidth, eps);
parameters.physicalHeight = positive(parameters.physicalHeight, eps);
parameters.targetPixelsPerUnit = nonnegative( ...
    parameters.targetPixelsPerUnit, 0);
parameters.maxUpsamplePercent = nonnegative( ...
    parameters.maxUpsamplePercent, 0);
applicationState.project.parameters = parameters;
if ~strcmpi(parameters.scaleMode, "Physical")
    applicationState.session.workflow.scaleReferenceEditing = false;
end
applicationState = batch_crop.cropGeometry.clearDerived(applicationState);
end

function value = positive(candidate, fallback)
value = scalar(candidate, fallback);
if value <= 0
    value = fallback;
end
end

function value = nonnegative(candidate, fallback)
value = scalar(candidate, fallback);
if value < 0
    value = fallback;
end
end

function value = scalar(candidate, fallback)
value = fallback;
if isnumeric(candidate) && isscalar(candidate) && isfinite(double(candidate))
    value = double(candidate);
end
end
