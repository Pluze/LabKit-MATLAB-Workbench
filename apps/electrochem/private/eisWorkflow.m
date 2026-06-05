% App-owned EIS workflow helper dispatch. Expected caller: labkit_EIS_app
% callbacks and temporary compatibility test handlers. Inputs are a command
% string plus the original helper arguments; outputs match the selected helper.
% This helper has no file side effects.
function varargout = eisWorkflow(command, varargin)
%EISWORKFLOW Dispatch app-owned EIS plot/export helpers.
% Expected caller: labkit_EIS_app callbacks and temporary compatibility test
% handlers. Inputs are a command string plus the original helper arguments.
% Outputs match the selected helper. This helper has no file side effects.

    switch string(command)
        case "labelForAxis"
            varargout{1} = labelForAxis(varargin{:});
        case "buildSummary"
            varargout{1} = buildSummary(varargin{:});
        case "plotOverlay"
            varargout{1} = plotOverlay(varargin{:});
        case "buildExportTable"
            varargout{1} = buildExportTable(varargin{:});
        case "valuesForAxis"
            varargout{1} = valuesForAxis(varargin{:});
        otherwise
            error('labkit:EIS:UnknownWorkflowCommand', ...
                'Unknown EIS workflow helper command: %s.', command);
    end
end
function txt = labelForAxis(axisName)
    txt = axisName;
end

function summary = buildSummary(items)
    summary = cell(0, 1);
    summary{end+1} = sprintf('Loaded files: %d', numel(items));
    for i = 1:numel(items)
        fmin = min(items(i).Freq, [], 'omitnan');
        fmax = max(items(i).Freq, [], 'omitnan');
        summary{end+1} = sprintf('%s | N=%d | Freq %.4g to %.4g Hz | order: %s', ...
            items(i).name, items(i).n, fmin, fmax, ternary(items(i).freqDesc, 'high->low', 'low->high/mixed'));
    end
end

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

%% App-local export
function T = buildExportTable(items, xName, yName, useLogX, useLogY)
    if nargin < 4
        useLogX = false;
    end
    if nargin < 5
        useLogY = false;
    end

    maxLen = 0;
    xCell = cell(1, numel(items));
    yCell = cell(1, numel(items));

    for i = 1:numel(items)
        [x, y] = filteredXY(items(i), xName, yName, useLogX, useLogY);
        xCell{i} = x(:);
        yCell{i} = y(:);
        maxLen = max(maxLen, numel(x));
    end

    T = table((1:maxLen).', 'VariableNames', {'RowIndex'});
    for i = 1:numel(items)
        safeName = matlab.lang.makeValidName(items(i).name);
        xVar = matlab.lang.makeValidName(sprintf('X_%s_%s', sanitizeAxisName(xName), safeName));
        yVar = matlab.lang.makeValidName(sprintf('Y_%s_%s', sanitizeAxisName(yName), safeName));
        T.(xVar) = padWithNaN(xCell{i}, maxLen);
        T.(yVar) = padWithNaN(yCell{i}, maxLen);
    end
end

%% Small app-local utilities
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

function padded = padWithNaN(v, n)
    padded = NaN(n, 1);
    if isempty(v)
        return;
    end
    padded(1:numel(v)) = v(:);
end

function out = sanitizeAxisName(txt)
    out = regexprep(lower(txt), '[^a-z0-9]+', '_');
    out = regexprep(out, '^_+|_+$', '');
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
