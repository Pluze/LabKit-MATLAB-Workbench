% Import one axes from a MATLAB FIG file into a preview axes. Expected caller
% is figure_studio.definitionActions; returns source style metadata and mutates
% only the destination axes.
function sourceStyle = importFigFile(filepath, dstAx)
    srcFig = openfig(char(filepath), 'invisible');
    cleanup = onCleanup(@() delete(srcFig));
    axesHandles = findobj(srcFig, 'Type', 'axes');
    axesHandles = axesHandles(~strcmp(get(axesHandles, 'Tag'), 'legend'));
    if isempty(axesHandles)
        error('labkit_FigureStudio_app:NoAxes', ...
            'The selected FIG file does not contain axes.');
    end
    srcAx = axesHandles(1);
    sourceStyle = figure_studio.sourceAxes.sourceStyle(srcAx);
    figure_studio.sourceAxes.copyToPreview(srcAx, dstAx);
end
