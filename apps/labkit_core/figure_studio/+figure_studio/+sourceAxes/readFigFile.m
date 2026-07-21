% Expected caller: Figure Studio source actions and session recreation. Input
% is one FIG path. Outputs are a serializable plot model and source style.
function [plotData, sourceStyle, resource] = readFigFile(filepath)
    srcFig = openfig(char(filepath), 'invisible');
    try
        axesHandles = findobj(srcFig, 'Type', 'axes');
        [axesHandles, ~] = figure_studio.sourceAxes.panelChoices(axesHandles);
        if isempty(axesHandles)
            error('labkit_FigureStudio_app:NoAxes', ...
                'The selected FIG file does not contain axes.');
        end
        resource = struct("figure", srcFig, "axes", axesHandles);
        [plotData, sourceStyle] = figure_studio.sourceAxes.selectPanel( ...
            resource, 1);
    catch cause
        deleteIfValid(srcFig);
        rethrow(cause);
    end
    if nargout < 3
        figure_studio.sourceAxes.closeResource(resource);
    end
end

function deleteIfValid(fig)
if isvalid(fig)
    delete(fig);
end
end
