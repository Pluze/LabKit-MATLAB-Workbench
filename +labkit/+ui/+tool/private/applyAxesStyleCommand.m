% Private UI tool helper. Expected caller: copied popout-figure controls.
% Input is the copied axes and a scalar command string. Side effects are
% limited to style properties on the copied axes, labels, legends, colorbars,
% and plotted graphics objects.
function applyAxesStyleCommand(ax, command)
    if isempty(ax) || ~isvalid(ax)
        return;
    end
    switch string(command)
        case "fontIncrease"
            adjustFont(ax, 1);
        case "fontDecrease"
            adjustFont(ax, -1);
        case "lineIncrease"
            adjustLineWidth(ax, 0.25);
        case "lineDecrease"
            adjustLineWidth(ax, -0.25);
        case "axesIncrease"
            adjustAxesLineWidth(ax, 0.25);
        case "axesDecrease"
            adjustAxesLineWidth(ax, -0.25);
        case "gridIncrease"
            adjustGrid(ax, 0.10);
        case "gridDecrease"
            adjustGrid(ax, -0.10);
        otherwise
            error('labkit:ui:InvalidPopoutStyleCommand', ...
                'Unsupported popout style command "%s".', string(command));
    end
    drawnow limitrate;
end

function adjustFont(ax, delta)
    handles = fontTargets(ax);
    for k = 1:numel(handles)
        handle = handles{k};
        if isempty(handle) || ~isvalid(handle) || ~isprop(handle, 'FontSize')
            continue;
        end
        try
            handle.FontSize = min(36, max(6, double(handle.FontSize) + delta));
        catch
        end
    end
end

function handles = fontTargets(ax)
    handles = {ax; ax.Title; ax.XLabel; ax.YLabel; ax.ZLabel};
    parentFig = ancestor(ax, 'figure');
    legends = findall(parentFig, 'Type', 'legend');
    colorbars = findall(parentFig, 'Type', 'colorbar');
    textObjects = findall(ax, 'Type', 'text');
    handles = [handles; num2cell(legends(:)); num2cell(colorbars(:)); ...
        num2cell(textObjects(:))];
end

function adjustLineWidth(ax, delta)
    handles = lineWidthTargets(ax);
    for k = 1:numel(handles)
        handle = handles(k);
        if isempty(handle) || ~isvalid(handle) || ~isprop(handle, 'LineWidth')
            continue;
        end
        try
            handle.LineWidth = max(0.25, double(handle.LineWidth) + delta);
        catch
        end
    end
end

function adjustAxesLineWidth(ax, delta)
    try
        ax.LineWidth = max(0.25, min(5, double(ax.LineWidth) + delta));
    catch
    end
end

function adjustGrid(ax, delta)
    try
        ax.XGrid = 'on';
        ax.YGrid = 'on';
        if isprop(ax, 'ZGrid')
            ax.ZGrid = 'on';
        end
        ax.GridAlpha = max(0.05, min(1, double(ax.GridAlpha) + delta));
        if isprop(ax, 'MinorGridAlpha')
            ax.MinorGridAlpha = max(0.05, min(1, double(ax.MinorGridAlpha) + delta));
        end
    catch
    end
end

function handles = lineWidthTargets(ax)
    handles = findall(ax, '-property', 'LineWidth');
    keep = false(size(handles));
    for k = 1:numel(handles)
        keep(k) = isDataGraphic(handles(k));
    end
    handles = handles(keep);
end

function tf = isDataGraphic(handle)
    tf = isa(handle, 'matlab.graphics.chart.primitive.Line') || ...
        isa(handle, 'matlab.graphics.chart.primitive.Scatter') || ...
        isa(handle, 'matlab.graphics.chart.primitive.Bar') || ...
        isa(handle, 'matlab.graphics.chart.primitive.Stem') || ...
        isa(handle, 'matlab.graphics.chart.primitive.ErrorBar') || ...
        isa(handle, 'matlab.graphics.primitive.Patch') || ...
        isa(handle, 'matlab.graphics.primitive.Surface') || ...
        isa(handle, 'matlab.graphics.primitive.Image');
end
