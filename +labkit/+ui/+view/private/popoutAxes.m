% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function newFig = popoutAxes(srcAx)
%POPOUTAXES Copy a UI axes into an editable MATLAB figure.
%
% Inputs:
%   srcAx - source UI axes.
%
% Output:
%   newFig - standalone MATLAB figure containing copied axes content.
%            Aspect ratio modes are set to auto for manual resizing.

    if isempty(srcAx) || ~isvalid(srcAx)
        error('labkit:ui:InvalidAxes', 'Source axes is not valid.');
    end

    titleText = axisLabelText(srcAx.Title);
    if strlength(titleText) == 0
        titleText = "LabKit Plot";
    end

    newFig = figure('Name', char(titleText), 'Color', 'w');
    dstAx = axes('Parent', newFig); %#ok<LAXES>
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
    unlockAspectRatio(dstAx);
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
    unlockAspectRatio(dstAx);

    addLegendIfNeeded(dstAx);
end

function unlockAspectRatio(ax)
    try
        ax.DataAspectRatioMode = 'auto';
        ax.PlotBoxAspectRatioMode = 'auto';
        ax.ActivePositionProperty = 'outerposition';
    catch
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
                names(end+1, 1) = name; %#ok<AGROW>
            end
        end
    end
    if ~isempty(names)
        legend(ax, 'show', 'Interpreter', 'none');
    end
end
