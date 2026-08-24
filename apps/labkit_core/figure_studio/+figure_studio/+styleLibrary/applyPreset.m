% App-owned implementation for figure_studio.styleLibrary.applyPreset within the figure_studio product workflow.
function state = applyPreset(state, preset, callbackContext)
%APPLYPRESET Apply a named style while preserving output geometry.
arguments
    state (1, 1) struct
    preset (1, 1) string
    callbackContext (1, 1) labkit.app.CallbackContext
end
p = state.project.parameters;
previous = p.style;
p.preset = preset;
if preset == "FIG default"
    p.style = state.session.cache.sourceDefaultStyle;
    if isempty(p.style)
        p.style = figure_studio.styleLibrary.styleForPreset(preset);
    end
else
    p.style = figure_studio.styleLibrary.styleForPreset(preset);
end
p.style.canvasWidth = previous.canvasWidth;
p.style.canvasHeight = previous.canvasHeight;
p.style.exportScale = previous.exportScale;
p.style.axesPosition = previous.axesPosition;
if isfield(previous, "outerMargin") && ~isempty(previous.outerMargin)
    p.style.outerMargin = previous.outerMargin;
end
p.gridChoice = onOff(p.style.gridVisible);
p.boundaryChoice = onOff(p.style.boundaryLines);
state.project.parameters = p;
state.session.cache.limitState.tickDir = string(p.style.tickDirection);
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
state.session.workflow.status = "Styled with " + preset + ".";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
callbackContext.log("info", "figure_studio.stylelibrary.applypreset.status", "Selected style mode: " + preset);
end

function value = onOff(tf)
if tf
    value = "On";
else
    value = "Off";
end
end
