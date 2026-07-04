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
        otherwise
            error('labkit:ui:InvalidPopoutStyleCommand', ...
                'Unsupported popout style command "%s".', string(command));
    end
    drawnow limitrate;
end

function adjustFont(ax, delta)
    handles = [ax; findall(ancestor(ax, 'figure'), '-property', 'FontSize')];
    for k = 1:numel(handles)
        handle = handles(k);
        if isempty(handle) || ~isvalid(handle) || ~isprop(handle, 'FontSize')
            continue;
        end
        try
            handle.FontSize = max(6, double(handle.FontSize) + delta);
        catch
        end
    end
end

function adjustLineWidth(ax, delta)
    handles = findall(ax, '-property', 'LineWidth');
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
