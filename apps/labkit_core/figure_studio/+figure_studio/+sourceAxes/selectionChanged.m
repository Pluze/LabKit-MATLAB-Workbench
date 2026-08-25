% App-owned implementation for figure_studio.sourceAxes.selectionChanged within the figure_studio product workflow.
function state = selectionChanged(state, selection, callbackContext)
%SELECTIONCHANGED Load the selected FIG and adopt its source presentation.
arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    callbackContext (1, 1) labkit.app.CallbackContext
end
state.project.annotations.embeddedPlot = [];
state.project.annotations.limitOverrides = emptyLimitOverrides();
state.project.annotations.panelIndex = 1;
if isempty(selection.Indices) || isempty(state.project.inputs.sources)
    state.session.cache.plotData = [];
    state.session.cache.currentSource = "";
    state.session.cache.sourceAxes = [];
    state.session.cache.sourcePanelChoices = "No panels";
    state.session.cache.limitState = figure_studio.sourceAxes.limitControls([]);
    state.session.editor = figure_studio.figureDocument.editorState([]);
    state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
    callbackContext.removeResource("sourceFigure");
    state.session.selection.currentIndex = 0;
    state.session.selection.panel = "No panels";
    state.session.workflow.status = "No FIG files loaded.";
    state.project.results.lastExport = [];
    state.project.results.lastOutputPath = "";
    return
end

paths = labkit.app.source.paths(state.project.inputs.sources);
index = min(selection.Indices(1), numel(paths));
sourcePath = paths(index);
[~, ~, resource] = figure_studio.sourceAxes.readFigFile(sourcePath);
callbackContext.setResource("sourceFigure", resource, ...
    @figure_studio.sourceAxes.closeResource);
[plotData, sourceStyle, sourceAxes, panelLabel, panelIndex] = ...
    figure_studio.sourceAxes.selectPanel(resource, 1);
[panelSnapshots, ~, panelChoices] = ...
    figure_studio.sourceAxes.extractPanelSnapshots(resource);
state.session.selection.currentIndex = index;
state.session.selection.panel = panelLabel;
state.session.cache.plotData = plotData;
state.session.cache.sourceAxes = sourceAxes;
state.session.cache.sourcePanelChoices = panelChoices;
state.session.cache.sourceDefaultStyle = sourceStyle;
state.session.cache.currentSource = sourcePath;
state.session.cache.limitState = figure_studio.sourceAxes.limitControls(plotData);
state.session.editor = figure_studio.figureDocument.editorState(panelSnapshots);
state.session.editor.activePanelId = ...
    state.session.editor.document.panels(panelIndex).id;
state.session.editor.selectedPanelIds = state.session.editor.activePanelId;
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
state.project.annotations.sourceDefaultStyle = sourceStyle;
state.project.annotations.panelIndex = panelIndex;
state = adoptSourceStyle(state, sourceStyle);
if strlength(state.project.parameters.outputFolder) == 0
    state.project.parameters.outputFolder = string(fileparts(sourcePath));
end
[~, name, extension] = fileparts(sourcePath);
state.session.workflow.status = "Opened " + string(name) + ...
    string(extension) + " — " + panelLabel + ".";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
callbackContext.log("info", ...
    "figure_studio.sourceaxes.selectionchanged.status", ...
    "Opened the selected FIG source.");
end

function state = adoptSourceStyle(state, sourceStyle)
p = state.project.parameters;
if p.preset == "FIG default"
    p.style = sourceStyle;
    p.aspectPreset = "Source";
    p.canvasSize = "Source size";
else
    [p.style, p.aspectPreset, p.canvasSize] = ...
        figure_studio.sourceAxes.applyStandardLayout( ...
        p.style, state.session.cache.plotData);
end
p.gridChoice = onOff(p.style.gridVisible);
p.boundaryChoice = onOff(p.style.boundaryLines);
state.project.parameters = p;
end

function value = onOff(tf)
if tf
    value = "On";
else
    value = "Off";
end
end

function limits = emptyLimitOverrides()
limits = struct("xLim", [], "yLim", []);
end
