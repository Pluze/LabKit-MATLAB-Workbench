function newFig = popoutAxes(srcAx)
%POPOUTAXES Copy a UI axes into an editable MATLAB figure.
%
% App-facing contract:
%   newFig = labkit.ui.tool.popoutAxes(srcAx)
%
% Inputs:
%   srcAx - source UI axes or axes handle.
%
% Output:
%   newFig - standalone MATLAB figure containing copied axes content. Plot
%       axes are freely resizable; image axes preserve data aspect ratio.

    if isempty(srcAx) || ~isvalid(srcAx)
        error('labkit:ui:InvalidAxes', 'Source axes is not valid.');
    end

    titleText = axisLabelText(srcAx.Title);
    if strlength(titleText) == 0
        titleText = "LabKit Plot";
    end

    newFig = figure('Name', char(titleText), 'Color', 'w');
    dstAx = axes('Parent', newFig);
    copyAxesState(srcAx, dstAx);

    children = flipud(srcAx.Children(:));
    if ~isempty(children)
        copyobj(children, dstAx);
    end
    applyAxesState(srcAx, dstAx);
end

function copyAxesState(srcAx, dstAx)
    props = {'XScale','YScale','ZScale','XDir','YDir','ZDir', ...
        'XLim','YLim','ZLim','CLim', ...
        'View','Box','XGrid','YGrid','ZGrid','Color','XColor','YColor','ZColor', ...
        'LineWidth','FontName','FontSize','FontWeight','FontAngle'};
    for k = 1:numel(props)
        try
            dstAx.(props{k}) = srcAx.(props{k});
        catch
        end
    end
    try
        colormap(dstAx, colormap(srcAx));
    catch
    end
end

function applyAxesState(srcAx, dstAx)
    title(dstAx, axisLabelText(srcAx.Title));
    xlabel(dstAx, axisLabelText(srcAx.XLabel));
    ylabel(dstAx, axisLabelText(srcAx.YLabel));
    zlabel(dstAx, axisLabelText(srcAx.ZLabel));

    try
        dstAx.XLimMode = srcAx.XLimMode;
        dstAx.YLimMode = srcAx.YLimMode;
        dstAx.ZLimMode = srcAx.ZLimMode;
        dstAx.CLimMode = srcAx.CLimMode;
    catch
    end
    applyAspectRatio(srcAx, dstAx);
    addLegendIfNeeded(dstAx);
end

function applyAspectRatio(srcAx, dstAx)
    if hasImageContent(srcAx)
        lockImageAspectRatio(srcAx, dstAx);
    else
        unlockAspectRatio(dstAx);
    end
end

function unlockAspectRatio(ax)
    try
        ax.DataAspectRatioMode = 'auto';
        ax.PlotBoxAspectRatioMode = 'auto';
        ax.ActivePositionProperty = 'outerposition';
    catch
    end
end

function lockImageAspectRatio(srcAx, dstAx)
    try
        dstAx.DataAspectRatio = srcAx.DataAspectRatio;
        dstAx.DataAspectRatioMode = 'manual';
        dstAx.PlotBoxAspectRatioMode = 'auto';
        dstAx.ActivePositionProperty = 'outerposition';
    catch
        axis(dstAx, 'image');
    end
end

function tf = hasImageContent(ax)
    children = ax.Children;
    tf = false;
    for k = 1:numel(children)
        if isgraphics(children(k), 'image')
            tf = true;
            return;
        end
    end
end

function text = axisLabelText(labelHandle)
    value = labelHandle.String;
    if iscell(value)
        text = string(strjoin(value, newline));
    else
        text = string(value);
    end
end

function addLegendIfNeeded(ax)
    children = ax.Children;
    names = strings(0, 1);
    for k = 1:numel(children)
        if isprop(children(k), 'DisplayName')
            name = string(children(k).DisplayName);
            if strlength(name) > 0 && ~startsWith(name, "_")
                names(end+1, 1) = name;
            end
        end
    end
    if ~isempty(names)
        legend(ax, 'show', 'Interpreter', 'none');
    end
end
