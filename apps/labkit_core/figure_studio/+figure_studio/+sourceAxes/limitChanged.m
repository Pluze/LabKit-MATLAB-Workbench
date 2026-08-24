%LIMITCHANGED Apply one manually edited X/Y limit pair to the active panel.
% Expected caller is the four bound numeric Figure Studio controls.
function state = limitChanged(state, changedId, callbackContext)
%LIMITCHANGED Persist valid editable limits and request a fresh viewport.
arguments
    state (1, 1) struct
    changedId (1, 1) string
    callbackContext (1, 1) labkit.app.CallbackContext
end
if isempty(state.session.cache.plotData)
    return;
end
controls = state.session.cache.limitState;
if any(changedId == ["xMin", "xMax"])
    pair = [controls.xMin controls.xMax];
    axisName = "xLim";
else
    pair = [controls.yMin controls.yMax];
    axisName = "yLim";
end
if any(~isfinite(pair)) || pair(1) >= pair(2)
    previous = state.session.cache.plotData.axes.(char(axisName));
    if axisName == "xLim"
        controls.xMin = previous(1);
        controls.xMax = previous(2);
    else
        controls.yMin = previous(1);
        controls.yMax = previous(2);
    end
    state.session.cache.limitState = controls;
    state.session.workflow.status = ...
        "Axis limits must be finite with the minimum below the maximum.";
    callbackContext.log("info", "figure_studio.sourceaxes.limitchanged.status", state.session.workflow.status);
    return;
end
state.session.cache.plotData.axes.(char(axisName)) = pair;
state.project.annotations.limitOverrides.(char(axisName)) = pair;
if isempty(state.project.inputs.sources)
    state.project.annotations.embeddedPlot = state.session.cache.plotData;
end
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
state.session.workflow.status = "Applied editable X/Y limits.";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
callbackContext.log("info", "figure_studio.sourceaxes.limitchanged.status", state.session.workflow.status);
end
