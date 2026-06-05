% Expected caller: EIS app runner. Inputs are an axes, EIS items, and plot
% options. Output is legend labels. Side effects are limited to redrawing axes.

function labels = plotOverlay(ax, items, opts)
    if nargin < 3
        opts = struct();
    end
    opts = fillPlotOptions(opts);

    cla(ax);
    ax.XScale = ternary(opts.logX, 'log', 'linear');
    ax.YScale = ternary(opts.logY, 'log', 'linear');
    axis(ax, 'normal');

    cmap = lines(numel(items));
    labels = cell(1, numel(items));
    marker = 'none';
    if opts.showMarkers
        marker = 'o';
    end

    hold(ax, 'on');
    for k = 1:numel(items)
        [x, y] = filteredXY(items(k), opts.xName, opts.yName, opts.logX, opts.logY);
        plot(ax, x, y, ...
            'LineWidth', opts.lineWidth, ...
            'Marker', marker, ...
            'MarkerSize', opts.markerSize, ...
            'Color', cmap(k, :));
        labels{k} = items(k).name;
    end
    hold(ax, 'off');

    xlabel(ax, labelForAxis(opts.xName));
    ylabel(ax, labelForAxis(opts.yName));
    title(ax, sprintf('%s vs %s (%d file%s)', ...
        labelForAxis(opts.yName), labelForAxis(opts.xName), numel(items), pluralS(numel(items))));

    if opts.showGrid
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end

    if opts.showLegend
        legend(ax, labels, 'Interpreter', 'none', 'Location', 'best');
    else
        legend(ax, 'off');
    end

    if isNyquistSelection(opts.xName, opts.yName)
        axis(ax, 'equal');
    end
end

function txt = labelForAxis(axisName)
    txt = axisName;
end

function opts = fillPlotOptions(opts)
    if ~isfield(opts, 'xName')
        opts.xName = 'Zreal (ohm)';
    end
    if ~isfield(opts, 'yName')
        opts.yName = '-Zimag (ohm)';
    end
    if ~isfield(opts, 'logX')
        opts.logX = false;
    end
    if ~isfield(opts, 'logY')
        opts.logY = false;
    end
    if ~isfield(opts, 'lineWidth')
        opts.lineWidth = 1.4;
    end
    if ~isfield(opts, 'markerSize')
        opts.markerSize = 6;
    end
    if ~isfield(opts, 'showMarkers')
        opts.showMarkers = true;
    end
    if ~isfield(opts, 'showLegend')
        opts.showLegend = true;
    end
    if ~isfield(opts, 'showGrid')
        opts.showGrid = true;
    end
end

function [x, y] = filteredXY(item, xName, yName, useLogX, useLogY)
    x = valuesForAxis(item, xName);
    y = valuesForAxis(item, yName);
    valid = isfinite(x) & isfinite(y);
    x = x(valid);
    y = y(valid);
    if useLogX
        validX = x > 0;
        x = x(validX);
        y = y(validX);
    end
    if useLogY
        validY = y > 0;
        x = x(validY);
        y = y(validY);
    end
end

function values = valuesForAxis(item, axisName)
    switch axisName
        case 'Freq (Hz)'
            values = item.Freq;
        case 'log10(Freq)'
            values = log10(item.Freq);
        case 'Time (s)'
            values = item.Time;
        case 'Point #'
            values = item.Pt;
        case 'Zreal (ohm)'
            values = item.Zreal;
        case 'Zimag (ohm)'
            values = item.Zimag;
        case '-Zimag (ohm)'
            values = item.negZimag;
        case 'Zmod (ohm)'
            values = item.Zmod;
        case 'Zphz (deg)'
            values = item.Zphz;
        case 'Idc (A)'
            values = item.Idc;
        case 'Vdc (V)'
            values = item.Vdc;
        otherwise
            error('Unsupported axis selection: %s', axisName);
    end
end

function tf = isNyquistSelection(xName, yName)
    tf = strcmp(xName, 'Zreal (ohm)') && ...
        (strcmp(yName, '-Zimag (ohm)') || strcmp(yName, 'Zimag (ohm)'));
end

function txt = pluralS(n)
    if n == 1
        txt = '';
    else
        txt = 's';
    end
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end
