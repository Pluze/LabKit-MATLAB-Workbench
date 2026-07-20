% App-owned implementation for batch_crop.scaleCalibration.barSettingsChanged within the batch_crop product workflow.
function applicationState = barSettingsChanged(applicationState, ~, ~)
value = applicationState.project.parameters.scaleBarLength;
if ~(isnumeric(value) && isscalar(value) && ...
        isfinite(double(value)) && value >= 0)
    applicationState.project.parameters.scaleBarLength = 0;
end
applicationState.session.view.scaleBar = [];
end
