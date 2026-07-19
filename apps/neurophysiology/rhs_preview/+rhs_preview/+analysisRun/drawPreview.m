% Expected caller: RHS Preview direct callbacks. Inputs are one axes handle and app state
% with an optional preview window. Side effect redraws stacked RHS waveforms.
function drawStackedPreview(axesById, S)
%DRAWSTACKEDPREVIEW Draw time-aligned stacked RHS preview traces.

    ax = axesById.main;
    labkit.app.plot.clearAxes(ax);
    title(ax, 'RHS Stacked Preview');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Channel');
    grid(ax, 'on');
    ax.Box = 'on';

    if isempty(S.preview) || isempty(S.preview.values)
        textHandle = text(ax, 0.5, 0.5, 'Select channels and read a window', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'Color', [0.35 0.35 0.35]);
        textHandle.HitTest = 'off';
        ax.XLim = [0 1];
        ax.YLim = [0 1];
        ax.YTick = [];
        return;
    end

    timeSec = double(S.preview.timeSec(:));
    values = double(S.preview.values);
    channels = string(S.preview.channels(:));
    nChannels = size(values, 2);
    if isempty(timeSec) || nChannels == 0
        return;
    end

    offsets = (1:nChannels).';
    hold(ax, 'on');
    colors = lines(max(nChannels, 1));
    for k = 1:nChannels
        y = normalizeTrace(values(:, k));
        lineHandle = plot(ax, timeSec, y + offsets(k), 'LineWidth', 0.8, ...
            'Color', colors(k, :));
        lineHandle.HitTest = 'off';
    end
    hold(ax, 'off');
    ax.YTick = offsets;
    ax.YTickLabel = cellstr(channels);
    ax.YLim = [0.25 nChannels + 0.75];
    if numel(timeSec) > 1
        ax.XLim = [timeSec(1) timeSec(end)];
    end
end

function y = normalizeTrace(y)
    y = fillmissing(double(y(:)), "linear", "EndValues", "nearest");
    y = y - median(y, "omitnan");
    scale = max(abs(y), [], "omitnan");
    if ~isfinite(scale) || scale <= 0
        scale = 1;
    end
    y = 0.40 .* (y ./ scale);
end
