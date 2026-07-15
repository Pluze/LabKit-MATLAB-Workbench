% Expected caller: Figure Studio source actions and session recreation. Input
% is one FIG path. Outputs are a serializable plot model and source style.
function [plotData, sourceStyle] = readFigFile(filepath)
    srcFig = openfig(char(filepath), 'invisible');
    cleanup = onCleanup(@() delete(srcFig));
    axesHandles = findobj(srcFig, 'Type', 'axes');
    axesHandles = axesHandles(~strcmp(get(axesHandles, 'Tag'), 'legend'));
    if isempty(axesHandles)
        error('labkit_FigureStudio_app:NoAxes', ...
            'The selected FIG file does not contain axes.');
    end
    srcAx = axesHandles(1);
    sourceStyle = figure_studio.sourceAxes.sourceStyle(srcAx, ...
        "PreserveAspect", false);
    plotData = figure_studio.resultFiles.extractAxesData(srcAx);
end
