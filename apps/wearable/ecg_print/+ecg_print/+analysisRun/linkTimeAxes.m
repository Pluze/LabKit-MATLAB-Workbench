% Expected caller: ECG Print's time-dashboard renderer. Inputs are the four
% time-domain axes and an install/remove phase. It synchronizes X limits and
% fits each Y range to finite visible line/scatter data whenever the time
% window changes. Listener lifetime is attached to the waveform axes.
function linkTimeAxes(axesById, phase)
%LINKTIMEAXES Link ECG time axes and auto-fit visible Y data.
ids = ["wave", "noise", "peak", "snr"];
axes = arrayfun(@(id) axesById.(id), ids);
listenerKey = "ecgPrintTimeAxesListeners";
busyKey = "ecgPrintTimeAxesBusy";

if isappdata(axes(1), listenerKey)
    listeners = getappdata(axes(1), listenerKey);
    for k = 1:numel(listeners)
        if ~isempty(listeners{k}) && isvalid(listeners{k})
            delete(listeners{k});
        end
    end
    rmappdata(axes(1), listenerKey);
end
if isappdata(axes(1), busyKey)
    rmappdata(axes(1), busyKey);
end
if string(phase) == "remove"
    return;
end

listeners = cell(1, numel(axes));
setappdata(axes(1), busyKey, false);
fullLimits = plottedXLimits(axes);
if ~isempty(fullLimits)
    setappdata(axes(1), busyKey, true);
    for ax = axes
        ax.XLim = fullLimits;
    end
    setappdata(axes(1), busyKey, false);
end
for k = 1:numel(axes)
    source = axes(k);
    listeners{k} = addlistener(source, 'XLim', 'PostSet', ...
        @(~, ~) synchronizeFrom(source, axes, busyKey));
end
setappdata(axes(1), listenerKey, listeners);
synchronizeFrom(axes(1), axes, busyKey);
end

function limits = plottedXLimits(axes)
    values = cell(1, numel(axes));
    for axisIndex = 1:numel(axes)
        graphics = allchild(axes(axisIndex));
        chunks = cell(1, numel(graphics));
        for graphicIndex = 1:numel(graphics)
            graphic = graphics(graphicIndex);
            if isprop(graphic, 'XData')
                x = double(graphic.XData(:));
                chunks{graphicIndex} = x(isfinite(x));
            end
        end
        values{axisIndex} = vertcat(chunks{:});
    end
    values = vertcat(values{:});
    if isempty(values)
        limits = [];
        return;
    end
    limits = [min(values) max(values)];
    if limits(1) == limits(2)
        padding = max(abs(limits(1)), 1) * 0.05;
        limits = limits + [-padding padding];
    end
end

function synchronizeFrom(source, axes, busyKey)
owner = axes(1);
if isappdata(owner, busyKey) && getappdata(owner, busyKey)
    return;
end
setappdata(owner, busyKey, true);
cleanup = onCleanup(@() setappdata(owner, busyKey, false));
limits = source.XLim;
for ax = axes
    if ~isequal(ax.XLim, limits)
        ax.XLim = limits;
    end
    fitVisibleY(ax);
end
clear cleanup
end

function fitVisibleY(ax)
limits = ax.XLim;
graphics = allchild(ax);
chunks = cell(1, numel(graphics));
for index = 1:numel(graphics)
    graphic = graphics(index);
    if ~isprop(graphic, 'XData') || ~isprop(graphic, 'YData')
        continue;
    end
    x = double(graphic.XData(:));
    y = double(graphic.YData(:));
    count = min(numel(x), numel(y));
    if count == 0
        continue;
    end
    x = x(1:count);
    y = y(1:count);
    visible = x >= limits(1) & x <= limits(2) & isfinite(y);
    chunks{index} = y(visible);
end
values = vertcat(chunks{:});
if isempty(values)
    return;
end
range = [min(values) max(values)];
span = diff(range);
if span == 0
    span = max(abs(range(1)), 1);
end
padding = 0.05 * span;
ax.YLim = range + [-padding padding];
end
