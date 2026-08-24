%AXISCHANGED Apply one explicit axis-presentation edit to the active panel.
% Expected caller is a Figure Studio axis control. The edit changes only
% presentation metadata; plotted coordinates and source graphics are intact.
function state = axisChanged(state, changedId, callbackContext)
arguments
    state (1, 1) struct
    changedId (1, 1) string
    callbackContext (1, 1) labkit.app.CallbackContext
end
if isempty(state.session.cache.plotData)
    return;
end
controls = state.session.cache.limitState;
field = char(changedId);
if ~isfield(controls, field)
    error("figure_studio:sourceAxes:UnknownAxisControl", ...
        "Unknown Figure Studio axis control '%s'.", changedId);
end
value = controls.(field);
if any(changedId == ["xScale", "yScale"]) && value == "log"
    limitName = extractBefore(changedId, "Scale") + "Lim";
    limits = double(state.session.cache.plotData.axes.(char(limitName)));
    if any(limits <= 0)
        previous = string(state.session.cache.plotData.axes.(field));
        controls.(field) = previous;
        state.session.cache.limitState = controls;
        state.session.workflow.status = ...
            "A logarithmic axis requires positive limits.";
        callbackContext.log("info", ...
            "figure_studio.sourceaxes.axischanged.status", ...
            state.session.workflow.status);
        return;
    end
end
state.session.cache.plotData.axes.(field) = value;
if changedId == "tickDir"
    state.project.parameters.style.tickDirection = value;
end
if isempty(state.project.inputs.sources)
    state.project.annotations.embeddedPlot = state.session.cache.plotData;
end
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
state.session.workflow.status = "Applied explicit axis presentation.";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
callbackContext.log("info", "figure_studio.sourceaxes.axischanged.status", ...
    state.session.workflow.status);
end
