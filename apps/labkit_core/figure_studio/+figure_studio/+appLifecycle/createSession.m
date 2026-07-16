% Expected caller: the LabKit V2 runtime. Input is a validated project.
% Output owns ephemeral source selection, decoded current plot, status, and logs.
function session = createSession(project)
    plotData = project.annotations.embeddedPlot;
    currentIndex = 0;
    currentSource = "";
    sourceDefaultStyle = project.annotations.sourceDefaultStyle;
    if isempty(plotData) && ~isempty(project.inputs.sources)
        currentIndex = 1;
        [plotData, sourceDefaultStyle] = loadSource(project.inputs.sources(1));
        currentSource = string( ...
            project.inputs.sources(1).reference.originalPath);
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

function [plotData, style] = loadSource(source)
    plotData = [];
    style = [];
    try
        [plotData, style] = figure_studio.sourceAxes.readFigFile( ...
            source.reference.originalPath);
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
