function info = plotCVCT(ax, curve, xsel, ysel, opts)
%PLOTCVCT Plot one selected X/Y pair from a parsed CV/CT curve.

    if nargin < 5
        opts = struct();
    end
    opts = fillOptions(opts);

    info = struct();
    info.ok = false;
    info.message = '';
    info.x = [];
    info.y = [];
    info.xName = '';
    info.yName = '';

    [x, y, xname, yname] = gamrywb.data.getCurveXY(curve, xsel, ysel);
    if isempty(x) || isempty(y)
        info.message = 'invalid X/Y';
        return;
    end

    if ~opts.holdPlot
        cla(ax);
    end

    plot(ax, x, y, 'LineWidth', opts.lineWidth);
    grid(ax, opts.showGrid);
    title(ax, curve.name, 'Interpreter', 'none');
    xlabel(ax, xname, 'Interpreter', 'none');
    ylabel(ax, yname, 'Interpreter', 'none');

    info.ok = true;
    info.message = 'OK';
    info.x = x;
    info.y = y;
    info.xName = xname;
    info.yName = yname;
end

function opts = fillOptions(opts)
    if ~isfield(opts, 'holdPlot')
        opts.holdPlot = false;
    end
    if ~isfield(opts, 'showGrid')
        opts.showGrid = true;
    end
    if ~isfield(opts, 'lineWidth')
        opts.lineWidth = 1.2;
    end
end
