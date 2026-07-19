function state = barSettingsChanged(state, ~, ~)
%BARSETTINGSCHANGED Sanitize scale-bar settings and clear transient geometry.
value = state.project.parameters.scaleBarLength;
if ~(isnumeric(value) && isscalar(value) && ...
        isfinite(double(value)) && value >= 0)
    state.project.parameters.scaleBarLength = 0;
end
state.session.view.scaleBar = [];
end
