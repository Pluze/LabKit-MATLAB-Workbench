% App-owned implementation for figure_studio.sourceAxes.selectionChanged within the figure_studio product workflow.
function state = selectionChanged(state, selection, callbackContext)
%SELECTIONCHANGED Load the selected FIG and adopt its source presentation.
arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    callbackContext (1, 1) labkit.app.CallbackContext
end
state.project.annotations.embeddedPlot = [];
if isempty(selection.Indices) || isempty(state.project.inputs.sources)
    state.session.cache.plotData = [];
    state.session.cache.currentSource = "";
    state.session.selection.currentIndex = 0;
    state.session.workflow.status = "No FIG files loaded.";
    state.project.results.lastExport = [];
    state.project.results.resultManifestPath = "";
    return
end
paths = callbackContext.resolveSourcePaths(state.project.inputs.sources);
index = min(selection.Indices(1), numel(paths));
sourcePath = paths(index);
[plotData, sourceStyle] = figure_studio.sourceAxes.readFigFile(sourcePath);
state.session.selection.currentIndex = index;
state.session.cache.plotData = plotData;
state.session.cache.sourceDefaultStyle = sourceStyle;
state.session.cache.currentSource = sourcePath;
state.project.annotations.sourceDefaultStyle = sourceStyle;
state = adoptSourceStyle(state, sourceStyle);
if strlength(state.project.parameters.outputFolder) == 0
    state.project.parameters.outputFolder = string(fileparts(sourcePath));
end
[~, name, extension] = fileparts(sourcePath);
state.session.workflow.status = "Opened " + ...
    string(name) + string(extension) + ".";
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
callbackContext.appendStatus("Opened FIG: " + sourcePath);
end

function state = adoptSourceStyle(state, sourceStyle)
p = state.project.parameters;
if p.preset == "FIG default"
    p.style = sourceStyle;
    p.aspectPreset = "Custom";
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
