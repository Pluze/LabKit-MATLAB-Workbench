%CREATESESSION Rebuild Figure Studio's transient view and decoded plot cache.
% Expected caller: App SDK through figure_studio.definition. Input is a
% validated current project. Existing source decode failures propagate so a
% damaged project cannot replace the live document with an empty cache.
function session = createSession(project, context)
    plotData = project.annotations.embeddedPlot;
    currentIndex = 0;
    currentSource = "";
    sourceDefaultStyle = project.annotations.sourceDefaultStyle;
    sourceAxes = [];
    sourcePanelChoices = "No panels";
    sourcePanel = "No panels";
    if isfield(project.annotations, "transientSourceAxes") && ...
            ~isempty(project.annotations.transientSourceAxes) && ...
            isgraphics(project.annotations.transientSourceAxes, "axes")
        resource = figure_studio.sourceAxes.cloneResource( ...
            project.annotations.transientSourceAxes);
        context.setResource("document", "sourceFigure", resource, ...
            @figure_studio.sourceAxes.closeResource);
        [plotData, sourceDefaultStyle, sourceAxes, sourcePanel, panelIndex] = ...
            figure_studio.sourceAxes.selectPanel(resource, ...
            requestedPanelIndex(project));
        [~, sourcePanelChoices] = figure_studio.sourceAxes.panelChoices( ...
            resource.axes);
        project.annotations.panelIndex = panelIndex;
    elseif isempty(plotData) && ~isempty(project.inputs.sources)
        currentIndex = 1;
        paths = context.resolveSourcePaths(project.inputs.sources);
        currentSource = paths(1);
        [~, ~, resource] = loadSource(currentSource);
        context.setResource("document", "sourceFigure", resource, ...
            @figure_studio.sourceAxes.closeResource);
        [plotData, sourceDefaultStyle, sourceAxes, sourcePanel, panelIndex] = ...
            figure_studio.sourceAxes.selectPanel(resource, ...
            requestedPanelIndex(project));
        [~, sourcePanelChoices] = figure_studio.sourceAxes.panelChoices( ...
            resource.axes);
        project.annotations.panelIndex = panelIndex;
    elseif ~isempty(plotData)
        currentSource = "Popout axes";
        sourcePanelChoices = "Saved panel";
        sourcePanel = "Saved panel";
    end
    plotData = applyLimitOverrides(plotData, project.annotations.limitOverrides);
    session = struct( ...
        "selection", struct( ...
            "files", labkit.app.event.ListSelection(), ...
            "currentIndex", currentIndex, ...
            "panel", sourcePanel), ...
        "workflow", struct("status", initialStatus(plotData)), ...
        "cache", struct( ...
            "plotData", plotData, ...
            "sourceAxes", sourceAxes, ...
            "sourceDefaultStyle", sourceDefaultStyle, ...
            "currentSource", currentSource, ...
            "sourcePanelChoices", sourcePanelChoices));
end

function plotData = applyLimitOverrides(plotData, overrides)
if isempty(plotData) || ~isstruct(overrides)
    return;
end
for field = ["xLim", "yLim"]
    if ~isfield(overrides, field)
        continue;
    end
    value = double(overrides.(field));
    if numel(value) == 2 && all(isfinite(value)) && value(1) < value(2)
        plotData.axes.(char(field)) = reshape(value, 1, 2);
    end
end
end

function [plotData, style, resource] = loadSource(sourcePath)
    [plotData, style, resource] = ...
        figure_studio.sourceAxes.readFigFile(sourcePath);
end

function index = requestedPanelIndex(project)
index = 1;
if isfield(project.annotations, "panelIndex") && ...
        isnumeric(project.annotations.panelIndex) && ...
        isscalar(project.annotations.panelIndex) && ...
        isfinite(project.annotations.panelIndex) && ...
        project.annotations.panelIndex >= 1
    index = floor(double(project.annotations.panelIndex));
end
end

function value = initialStatus(plotData)
    if isempty(plotData)
        value = "Load a MATLAB .fig file or send a popout plot to Studio.";
    else
        value = "Restored figure source.";
    end
end
