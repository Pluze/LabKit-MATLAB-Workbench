%CREATESESSION Rebuild Figure Studio's transient view and decoded plot cache.
% Expected caller: Runtime V2 through figure_studio.definition. Input is a
% validated current project. File-read failures leave the source unloaded.
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
        "workflow", struct( ...
            "logLines", strings(0, 1), ...
            "status", initialStatus(plotData)), ...
        "view", struct(), ...
        "cache", struct( ...
            "plotData", plotData, ...
            "sourceDefaultStyle", sourceDefaultStyle, ...
            "currentSource", currentSource));
end

function [plotData, style] = loadSource(sourcePath)
    plotData = [];
    style = [];
    try
        [plotData, style] = ...
            figure_studio.sourceAxes.readFigFile(sourcePath);
    catch
        % Missing portable references remain unloaded until relinked.
    end
end

function value = initialStatus(plotData)
    if isempty(plotData)
        value = "Load a MATLAB .fig file or send a popout plot to Studio.";
    else
        value = "Restored figure source.";
    end
end
