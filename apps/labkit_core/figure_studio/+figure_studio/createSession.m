%CREATESESSION Rebuild Figure Studio's transient view and decoded plot cache.
% Expected caller: Runtime V2 through figure_studio.definition. Input is a
% validated current project. Existing source decode failures propagate so a
% damaged project cannot replace the live document with an empty cache.
function session = createSession(project)
    plotData = project.annotations.embeddedPlot;
    currentIndex = 0;
    currentSource = "";
    sourceDefaultStyle = project.annotations.sourceDefaultStyle;
    if isempty(plotData) && ~isempty(project.inputs.sources)
        currentIndex = 1;
        currentSource = labkit.ui.runtime.sourcePaths( ...
            project.inputs.sources(1));
        [plotData, sourceDefaultStyle] = loadSource(currentSource);
    elseif ~isempty(plotData)
        currentSource = "Popout axes";
    end
    session = struct( ...
        "selection", struct("currentIndex", currentIndex), ...
        "workflow", struct("status", initialStatus(plotData)), ...
        "cache", struct( ...
            "plotData", plotData, ...
            "sourceDefaultStyle", sourceDefaultStyle, ...
            "currentSource", currentSource));
end

function [plotData, style] = loadSource(sourcePath)
    [plotData, style] = figure_studio.sourceAxes.readFigFile(sourcePath);
end

function value = initialStatus(plotData)
    if isempty(plotData)
        value = "Load a MATLAB .fig file or send a popout plot to Studio.";
    else
        value = "Restored figure source.";
    end
end
