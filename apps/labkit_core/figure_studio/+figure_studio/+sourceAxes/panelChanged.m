% App-owned implementation for Figure Studio's active single-panel selector.
function state = panelChanged(state, ~, callbackContext)
arguments
    state (1, 1) struct
    ~
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
state.session.cache.limitState = figure_studio.sourceAxes.limitControls(plotData);
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
state.project.annotations.sourceDefaultStyle = sourceStyle;
state.project.annotations.panelIndex = panelIndex;
state.project.annotations.limitOverrides = emptyLimitOverrides();
p = state.project.parameters;
if p.preset == "FIG default"
    p.style = sourceStyle;
    p.aspectPreset = "Source";
    p.canvasSize = "Source size";
else
    [p.style, p.aspectPreset, p.canvasSize] = ...
        figure_studio.sourceAxes.applyStandardLayout( ...
        p.style, plotData);
end
p.gridChoice = onOff(p.style.gridVisible);
p.boundaryChoice = onOff(p.style.boundaryLines);
state.project.parameters = p;
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
state.session.workflow.status = "Editing " + panelLabel + ".";
callbackContext.log("info", "figure_studio.sourceaxes.panelchanged.status", ...
    "Selected a figure panel.");
end

function limits = emptyLimitOverrides()
limits = struct("xLim", [], "yLim", []);
end

function value = onOff(tf)
if tf
    value = "On";
else
    value = "Off";
end
end
