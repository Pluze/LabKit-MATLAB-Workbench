% Expected caller: the registered Chrono Overlay V2 renderer. Inputs are one
% axes and a prepared model containing items, plot options, and signal kind.
% Side effects are limited to redrawing the supplied axes.
function renderOverlayAxis(ax, model)
    options = model.options;
    items = model.items;
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if isempty(items)
        renderEmpty(ax, model.signal);
        return;
    end

    colorMap = lines(numel(items));
    hold(ax, 'on');
    labels = cell(1, numel(items));
    plotLines = gobjects(1, numel(items));
    for k = 1:numel(items)
        item = items(k);
        plotLines(k) = plot(ax, chooseX(item, options.xAxis), ...
            signalValues(item, model.signal), ...
            'LineWidth', options.lineWidth, 'Color', colorMap(k, :));
        labels{k} = char(item.name);
    end
    hold(ax, 'off');
    labkit.ui.plot.fit(ax, plotLines(isgraphics(plotLines)));
    xlabel(ax, axisLabel(options.xAxis));
    [titleText, yLabel] = signalLabels(model.signal, numel(items));
    ylabel(ax, yLabel);
    title(ax, titleText);
    setGrid(ax, options.showGrid);
    setLegend(ax, labels, options.showLegend);
end

function renderEmpty(ax, signal)
    if signal == "voltage"
        title(ax, 'Voltage');
        ylabel(ax, 'Vf (V)');
    else
        title(ax, 'Current');
        ylabel(ax, 'Im (A)');
    end
    xlabel(ax, 'Blank-Center Aligned Time (s)');
end

function values = signalValues(item, signal)
    if signal == "voltage"
        values = firstAvailable(item, "Vf_V", "Vf");
    else
        values = firstAvailable(item, "Im_A", "Im");
    end
end

function values = firstAvailable(item, preferred, fallback)
    values = [];
    if isfield(item, preferred) && ~isempty(item.(preferred))
        values = item.(preferred)(:);
    elseif isfield(item, fallback) && ~isempty(item.(fallback))
        values = item.(fallback)(:);
    end
end

function x = chooseX(item, mode)
    % Constant: 1000 converts seconds to milliseconds for the selected axis.
    millisecondsPerSecond = 1e3;
    switch string(mode)
        case "Time (ms)"
            x = millisecondsPerSecond * alignedTime(item);
        case "Sample #"
            x = samplePoint(item);
        otherwise
            x = alignedTime(item);
    end
end

function values = alignedTime(item)
    values = firstAvailable(item, "tAligned_s", "tAligned");
end

function values = samplePoint(item)
    if isfield(item, 'pt') && ~isempty(item.pt)
        values = item.pt(:);
    else
        values = (0:numel(alignedTime(item))-1).';
    end
end

function text = axisLabel(mode)
    switch string(mode)
        case "Time (ms)"
            text = 'Blank-Center Aligned Time (ms)';
        case "Sample #"
            text = 'Sample #';
        otherwise
            text = 'Blank-Center Aligned Time (s)';
    end
end

function [titleText, yLabel] = signalLabels(signal, count)
    suffix = 's';
    if count == 1
        suffix = '';
    end
    if signal == "voltage"
        titleText = sprintf('Voltage Overlay (%d file%s)', count, suffix);
        yLabel = 'Vf (V)';
    else
        titleText = sprintf('Current Overlay (%d file%s)', count, suffix);
        yLabel = 'Im (A)';
    end
end

function setGrid(ax, visible)
    if visible
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end
end

function setLegend(ax, labels, visible)
    if visible
        legend(ax, labels, 'Interpreter', 'none', 'Location', 'best');
    else
        legend(ax, 'off');
    end
end
