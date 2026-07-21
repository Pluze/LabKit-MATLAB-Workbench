% App-owned implementation for Figure Studio's active single-panel selector.
function state = panelChanged(state, event, callbackContext)
arguments
    state (1, 1) struct
    event
    callbackContext (1, 1) labkit.app.CallbackContext
end
resource = callbackContext.getResource("document", "sourceFigure");
[~, labels] = figure_studio.sourceAxes.panelChoices(resource.axes);
requested = string(state.session.selection.panel);
panelIndex = find(labels == requested, 1);
if isempty(panelIndex)
    panelIndex = 1;
end
[plotData, sourceStyle, sourceAxes, panelLabel, panelIndex] = ...
    figure_studio.sourceAxes.selectPanel(resource, panelIndex);
state.session.selection.panel = panelLabel;
state.session.cache.plotData = plotData;
state.session.cache.sourceAxes = sourceAxes;
state.session.cache.sourceDefaultStyle = sourceStyle;
state.session.cache.sourcePanelChoices = labels;
state.project.annotations.sourceDefaultStyle = sourceStyle;
state.project.annotations.panelIndex = panelIndex;
state.project.annotations.limitOverrides = emptyLimitOverrides();
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
state.session.workflow.status = "Editing " + panelLabel + ".";
callbackContext.appendStatus("Selected FIG " + panelLabel + ".");
end

function limits = emptyLimitOverrides()
limits = struct("xLim", [], "yLim", []);
end
