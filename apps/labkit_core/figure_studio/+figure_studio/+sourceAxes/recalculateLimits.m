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
    currentSourceAxes(state), state.session.editor.document);
cleanup = onCleanup(@() deleteIfValid(fig));
ax.XLimMode = "auto";
ax.YLimMode = "auto";
drawnow nocallbacks
state.session.cache.plotData.axes.xLim = ax.XLim;
state.session.cache.plotData.axes.yLim = ax.YLim;
panelId = state.session.editor.activePanelId;
state.session.editor.document = figure_studio.figureDocument.setAxisLimits( ...
    state.session.editor.document, panelId, "x", ax.XLim);
state.session.editor.document = figure_studio.figureDocument.setAxisLimits( ...
    state.session.editor.document, panelId, "y", ax.YLim);
state.project.annotations.limitOverrides = struct( ...
    "xLim", ax.XLim, "yLim", ax.YLim);
state.session.cache.limitState = ...
    figure_studio.sourceAxes.limitControls(state.session.cache.plotData);
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
if isempty(state.project.inputs.sources)
    state.project.annotations.embeddedPlot = state.session.cache.plotData;
end

function source = currentSourceAxes(state)
source = [];
if state.session.editor.nativePassThrough
    source = state.session.cache.sourceAxes;
end
end
state.session.workflow.status = "Recalculated X/Y limits from visible graphics.";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
callbackContext.log("info", "figure_studio.sourceaxes.recalculatelimits.status", state.session.workflow.status);
end

function deleteIfValid(fig)
if isvalid(fig)
    delete(fig);
end
end
