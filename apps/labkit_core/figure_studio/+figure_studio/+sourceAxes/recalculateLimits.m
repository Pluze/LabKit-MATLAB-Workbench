% Expected caller: the Figure Studio recalculate-limits action. Inputs are
% runtime state and callback context. Output is updated state; side effects
% are a transient styled figure and an appended user-visible status message.
function state = recalculateLimits(state, callbackContext)
%RECALCULATELIMITS Fit the current Figure Studio snapshot to visible X/Y data.
arguments
    state (1, 1) struct
    callbackContext (1, 1) labkit.app.CallbackContext
end
if isempty(state.session.cache.plotData)
    return;
end
[fig, ax] = figure_studio.resultFiles.createStyledFigure( ...
    state.session.cache.plotData, state.project.parameters.style, ...
    state.session.cache.sourceAxes);
cleanup = onCleanup(@() deleteIfValid(fig));
ax.XLimMode = "auto";
ax.YLimMode = "auto";
drawnow nocallbacks
state.session.cache.plotData.axes.xLim = ax.XLim;
state.session.cache.plotData.axes.yLim = ax.YLim;
state.project.annotations.limitOverrides = struct( ...
    "xLim", ax.XLim, "yLim", ax.YLim);
state.session.cache.limitState = ...
    figure_studio.sourceAxes.limitControls(state.session.cache.plotData);
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
if isempty(state.project.inputs.sources)
    state.project.annotations.embeddedPlot = state.session.cache.plotData;
end
state.session.workflow.status = "Recalculated X/Y limits from visible graphics.";
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
callbackContext.appendStatus(state.session.workflow.status);
end

function deleteIfValid(fig)
if isvalid(fig)
    delete(fig);
end
end
