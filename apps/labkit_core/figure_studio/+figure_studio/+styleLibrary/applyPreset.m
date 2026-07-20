function state = applyPreset(state, preset, callbackContext)
%APPLYPRESET Apply a named style while preserving canvas/export geometry.
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
    p.style.canvasWidth = previous.canvasWidth;
    p.style.canvasHeight = previous.canvasHeight;
    p.style.exportScale = previous.exportScale;
end
p.gridChoice = onOff(p.style.gridVisible);
p.boundaryChoice = onOff(p.style.boundaryLines);
state.project.parameters = p;
state.session.workflow.status = "Styled with " + preset + ".";
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
callbackContext.appendStatus("Selected style mode: " + preset);
end

function value = onOff(tf)
if tf
    value = "On";
else
    value = "Off";
end
end
