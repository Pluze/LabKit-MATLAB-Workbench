% Expected callers: the App SDK axis renderer and plot export. Inputs are
% an axes, EIS items, and plot options. Output is legend labels. Side effects
% are limited to redrawing axes.

function labels = plotOverlay(ax, items, opts)
    if nargin < 3
        opts = struct();
    end
    opts = fillPlotOptions(opts);

    % During frequency adjustment the same scans stay on the same axes.
    % Update their coordinates in place; grouped error bars retain a full redraw.
    previous = flipud(ax.Children(:));
    reuse = isfield(opts, "frequencyLogRange") && ~isfield(items, "members") && ...
        ~isempty(previous) && numel(previous) == numel(items) && ...
        all(isgraphics(previous, "line")) && ...
        all(arrayfun(@(h) strcmp(h.Tag, "eisRawScan"), previous)) && ...
        strcmp(ax.XScale, ternary(opts.logX, 'log', 'linear')) && ...
        strcmp(ax.YScale, ternary(opts.logY, 'log', 'linear'));
    if ~reuse
        labkit.app.plot.clearAxes(ax, ResetScale=true);
    end

    cmap = lines(numel(items));
    labels = cell(1, numel(items));
    marker = 'none';
    if opts.showMarkers
        marker = 'o';
    end

    if ~reuse, hold(ax, 'on'); end
    plottedLines = gobjects(1, numel(items));
    for k = 1:numel(items)
        if isfield(items, "members")
            stats = eis.analysisRun.groupCoordinates(items(k).members, ...
                opts.xName, opts.yName, opts.impedanceUnit);
            [x, y] = validCoordinates(stats.x, stats.y, opts.logX, opts.logY);
            [x, y] = frequencyMask(x, y, stats.frequency, opts);
            xLower = stats.xSD;
            yLower = stats.ySD;
            if opts.logX, xLower(x - xLower <= 0) = NaN; end
            if opts.logY, yLower(y - yLower <= 0) = NaN; end
            plottedLines(k) = errorbar(ax, x, y, yLower, stats.ySD, ...
                xLower, stats.xSD, 'LineWidth', opts.lineWidth, ...
                'Marker', marker, 'MarkerSize', opts.markerSize, 'Color', cmap(k, :));
            % The common fitter reads XData/YData, so retain error extents as
            % non-rendering graphics to include uncertainty in every fit action.
            plot(ax, [x; x-xLower; x+stats.xSD], ...
                [y; y-yLower; y+stats.ySD], ...
                'Visible', 'off', 'HandleVisibility', 'off', 'Tag', 'groupErrorExtents');
        else
            [x, y] = filteredXY(items(k), opts.xName, opts.yName, ...
                opts.impedanceUnit, opts.logX, opts.logY);
            [x, y] = frequencyMask(x, y, items(k).freq_Hz, opts);
            if reuse
                plottedLines(k) = previous(k);
                set(previous(k), XData=x, YData=y, LineWidth=opts.lineWidth, ...
                    Marker=marker, MarkerSize=opts.markerSize, Color=cmap(k,:));
            else
                plottedLines(k) = plot(ax, x, y, ...
                    'LineWidth', opts.lineWidth, 'Marker', marker, ...
                    'MarkerSize', opts.markerSize, 'Color', cmap(k,:), 'Tag', 'eisRawScan');
            end
        end
        labels{k} = items(k).name;
        if isfield(items, "members")
            labels{k} = sprintf('%s (scans=%d)', items(k).name, numel(items(k).members));
        end
    end
    if ~reuse, hold(ax, 'off'); end
    % Set logarithmic scales only after positive-only data has established
    % valid automatic limits. Applying a log scale while stale manual limits
    % are still negative makes MATLAB warn before the redraw can refit them.
    ax.XScale = ternary(opts.logX, 'log', 'linear');
    ax.YScale = ternary(opts.logY, 'log', 'linear');
    overview = isfield(opts, "overviewTitle");
    nyquist = overview && ~opts.logX;
    if ~nyquist
        labkit.app.plot.fitAxesToGraphics(ax);
    end

    xLabel = eis.overlayPlot.labelForAxis(opts.xName, opts.impedanceUnit);
    yLabel = eis.overlayPlot.labelForAxis(opts.yName, opts.impedanceUnit);
    if ~strcmp(ax.XLabel.String, xLabel), xlabel(ax, xLabel); end
    if ~strcmp(ax.YLabel.String, yLabel), ylabel(ax, yLabel); end
    if overview
        caption = opts.overviewTitle;
    else
        kind = "file";
        detail = "";
        if isfield(items, "members")
            kind = "group";
            detail = "; mean ± SD";
        end
        caption = sprintf('%s vs %s (%d %s%s%s)', ...
            yLabel, xLabel, numel(items), kind, pluralS(numel(items)), detail);
    end
    if ~strcmp(ax.Title.String, caption), title(ax, caption); end

    if opts.showGrid
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end

    if opts.showLegend
        if nyquist
            names = wrapLegendLabels(string(labels));
            if ~reuse || isempty(ax.Legend) || ~isequal(string(ax.Legend.String(:)), names(:))
                legend(ax, plottedLines, names, Interpreter="none", Location="eastoutside", Box="off");
            end
        else
            legend(ax, plottedLines, labels, Interpreter="none", Location="best");
        end
    elseif ~isempty(ax.Legend)
        legend(ax, 'off');
    end
end

function opts = fillPlotOptions(opts)
    items = eis.overlayPlot.axisItems();
    if ~isfield(opts, 'xName')
        opts.xName = char(items(5));
    end
    if ~isfield(opts, 'yName')
        opts.yName = char(items(7));
    end
    if ~isfield(opts, 'logX')
        opts.logX = false;
    end
    if ~isfield(opts, 'impedanceUnit')
        units = eis.impedanceDisplay.catalog();
        opts.impedanceUnit = units.choices(3);
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

function [x, y] = filteredXY( ...
        item, xName, yName, impedanceUnit, useLogX, useLogY)
    x = eis.analysisRun.valuesForAxis(item, xName, impedanceUnit);
    y = eis.analysisRun.valuesForAxis(item, yName, impedanceUnit);
    [x, y] = validCoordinates(x, y, useLogX, useLogY);
end

function [x, y] = validCoordinates(x, y, useLogX, useLogY)
    valid = isfinite(x) & isfinite(y);
    if useLogX, valid = valid & x > 0; end
    if useLogY, valid = valid & y > 0; end
    % Retain positions so invalid samples break a curve instead of joining
    % unrelated neighboring samples across missing or nonpositive values.
    x(~valid) = NaN;
    y(~valid) = NaN;
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

function [x, y] = frequencyMask(x, y, frequency, opts)
    if ~isfield(opts, "frequencyLogRange"), return; end
    positive = isfinite(frequency(:)) & frequency(:) > 0;
    logFrequency = NaN(size(frequency(:)));
    logFrequency(positive) = log10(frequency(positive));
    keep = positive & ...
        logFrequency >= opts.frequencyLogRange(1) & ...
        logFrequency <= opts.frequencyLogRange(2);
    x(~keep) = NaN;
    y(~keep) = NaN;
end

function labels = wrapLegendLabels(labels)
% Bound a side legend's width without shortening the displayed source names.
maximumLineLength = 22;
for k = 1:numel(labels)
    remaining = char(labels(k));
    lines = strings(numel(remaining)+1, 1);
    lineCount = 0;
    while numel(remaining) > maximumLineLength
        cut = find(ismember(remaining(1:maximumLineLength), '-_ '), 1, 'last');
        if isempty(cut), cut = maximumLineLength; end
        lineCount = lineCount + 1;
        lines(lineCount) = string(remaining(1:cut));
        remaining = remaining(cut+1:end);
    end
    labels(k) = join([lines(1:lineCount); string(remaining)], newline);
end
end
