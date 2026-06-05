% Expected caller: chrono overlay app runner. Inputs are voltage/current axes,
% aligned item structs, and plot option fields. Side effects are limited to
% redrawing the supplied axes.

function plotVTIT(axV, axI, items, opts)
    if nargin < 4
        opts = struct();
    end
    if ~isfield(opts, 'xAxis')
        opts.xAxis = 'Time (s)';
    end
    if ~isfield(opts, 'lineWidth')
        opts.lineWidth = 1.3;
    end
    if ~isfield(opts, 'showGrid')
        opts.showGrid = true;
    end
    if ~isfield(opts, 'showLegend')
        opts.showLegend = true;
    end

    cla(axV);
    cla(axI);

    if isempty(items)
        title(axV, 'Voltage');
        title(axI, 'Current');
        xlabel(axV, 'Blank-Center Aligned Time (s)');
        xlabel(axI, 'Blank-Center Aligned Time (s)');
        ylabel(axV, 'Vf (V)');
        ylabel(axI, 'Im (A)');
        return;
    end

    cmap = lines(numel(items));
    hold(axV, 'on');
    hold(axI, 'on');

    labels = cell(1, numel(items));
    for k = 1:numel(items)
        item = items(k);
        x = chooseX(item, opts.xAxis);
        plot(axV, x, chronoVoltage(item), 'LineWidth', opts.lineWidth, 'Color', cmap(k, :));
        plot(axI, x, chronoCurrent(item), 'LineWidth', opts.lineWidth, 'Color', cmap(k, :));
        labels{k} = char(item.name);
    end

    hold(axV, 'off');
    hold(axI, 'off');

    xlabelText = axisLabel(opts.xAxis);
    xlabel(axV, xlabelText);
    xlabel(axI, xlabelText);
    ylabel(axV, 'Vf (V)');
    ylabel(axI, 'Im (A)');
    title(axV, sprintf('Voltage Overlay (%d file%s)', numel(items), pluralS(numel(items))));
    title(axI, sprintf('Current Overlay (%d file%s)', numel(items), pluralS(numel(items))));

    if opts.showGrid
        grid(axV, 'on');
        grid(axI, 'on');
    else
        grid(axV, 'off');
        grid(axI, 'off');
    end

    if opts.showLegend
        legend(axV, labels, 'Interpreter', 'none', 'Location', 'best');
        legend(axI, labels, 'Interpreter', 'none', 'Location', 'best');
    else
        legend(axV, 'off');
        legend(axI, 'off');
    end
end

function v = chronoVoltage(item)
    if isfield(item, 'Vf') && ~isempty(item.Vf)
        v = item.Vf(:);
    elseif isfield(item, 'Vf_V') && ~isempty(item.Vf_V)
        v = item.Vf_V(:);
    else
        v = [];
    end
end

function i = chronoCurrent(item)
    if isfield(item, 'Im') && ~isempty(item.Im)
        i = item.Im(:);
    elseif isfield(item, 'Im_A') && ~isempty(item.Im_A)
        i = item.Im_A(:);
    else
        i = [];
    end
end

function x = chooseX(item, mode)
    switch mode
        case 'Time (ms)'
            x = 1e3 * chronoAlignedTime(item);
        case 'Sample #'
            x = samplePoint(item);
        otherwise
            x = chronoAlignedTime(item);
    end
end

function t = chronoAlignedTime(item)
    if isfield(item, 'tAligned') && ~isempty(item.tAligned)
        t = item.tAligned(:);
    elseif isfield(item, 'tAligned_s') && ~isempty(item.tAligned_s)
        t = item.tAligned_s(:);
    else
        t = [];
    end
end

function pt = samplePoint(item)
    if isfield(item, 'pt') && ~isempty(item.pt)
        pt = item.pt(:);
    else
        pt = (0:numel(chronoAlignedTime(item))-1).';
    end
end

function txt = axisLabel(mode)
    switch mode
        case 'Time (ms)'
            txt = 'Blank-Center Aligned Time (ms)';
        case 'Sample #'
            txt = 'Sample #';
        otherwise
            txt = 'Blank-Center Aligned Time (s)';
    end
end

function s = pluralS(n)
    if n == 1
        s = '';
    else
        s = 's';
    end
end
