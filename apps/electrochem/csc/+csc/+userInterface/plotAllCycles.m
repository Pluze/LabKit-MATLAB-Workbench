% Expected caller: CSC app runner. Inputs are one axes, parsed CV/CT curves,
% selected X/Y names, and display options. Side effects are limited to
% redrawing the supplied axes for the all-cycle view.

function info = plotAllCycles(ax, curves, xSelection, ySelection, opts)
%PLOTALLCYCLES Plot all CSC cycles with per-cycle colors.

    if nargin < 5
        opts = struct();
    end
    opts = fillOptions(opts, numel(curves));

    labkit.ui.plot.clear(ax, "ResetScale", true);
    hold(ax, 'on');
    colors = lines(max(1, numel(curves)));
    labels = struct('x', char(string(xSelection)), 'y', char(string(ySelection)));
    plotted = 0;
    for iCurve = opts.curveIndices
        curve = curves(iCurve);
        [x, y, xName, yName] = labkit.dta.getCurveXY(curve, xSelection, ySelection);
        if isempty(x) || isempty(y) || numel(x) ~= numel(y)
            continue;
        end
        x = alignedX(x, xName);
        labels.x = alignedXLabel(xName);
        labels.y = yName;
        base = colors(iCurve, :);
        if strcmp(ySelection, 'Im')
            plotSplitCurrent(ax, x, y, base);
        else
            plot(ax, x(:), y(:), 'Color', base, 'LineWidth', opts.lineWidth);
        end
        plotted = plotted + 1;
    end
    hold(ax, 'off');

    grid(ax, opts.showGrid);
    title(ax, opts.title, 'Interpreter', 'none');
    xlabel(ax, labels.x, 'Interpreter', 'none');
    ylabel(ax, labels.y, 'Interpreter', 'none');
    labkit.ui.plot.fit(ax);

    info = struct('ok', plotted > 0, 'plotted', plotted, ...
        'xName', labels.x, 'yName', labels.y);
end

function opts = fillOptions(opts, curveCount)
    if ~isfield(opts, 'showGrid')
        opts.showGrid = true;
    end
    if ~isfield(opts, 'lineWidth')
        opts.lineWidth = 1.1;
    end
    if ~isfield(opts, 'title')
        choices = csc.userInterface.analysisChoices();
        opts.title = char(choices.allCycles);
    end
    if ~isfield(opts, 'curveIndices')
        opts.curveIndices = 1:curveCount;
    end
end

function x = alignedX(x, xName)
    x = x(:);
    if strcmp(xName, 'T') && ~isempty(x)
        x = x - x(1);
    end
end

function label = alignedXLabel(xName)
    if strcmp(xName, 'T')
        label = 'Cycle time (s)';
    else
        label = xName;
    end
end

function plotSplitCurrent(ax, x, y, base)
    cathY = y(:);
    anodY = y(:);
    cathY(cathY >= 0) = NaN;
    anodY(anodY <= 0) = NaN;
    plot(ax, x(:), cathY, 'Color', darker(base), 'LineWidth', 1.1);
    plot(ax, x(:), anodY, 'Color', lighter(base), 'LineWidth', 1.1);
end

function color = darker(base)
    color = max(0, 0.58 * base);
end

function color = lighter(base)
    color = min(1, 1 - 0.45 * (1 - base));
end
