% App-owned chrono overlay workflow helper dispatch. Expected caller:
% labkit_ChronoOverlay_app callbacks and workflow tests.
% Inputs are a command string plus the original helper arguments; outputs match
% the selected helper. This helper has no file side effects.
function varargout = chronoOverlayWorkflow(command, varargin)
%CHRONOOVERLAYWORKFLOW Dispatch app-owned chrono overlay helpers.
% Expected caller: labkit_ChronoOverlay_app callbacks and temporary compatibility
% workflow tests. Inputs are a command string plus the original helper arguments.
% Outputs match the selected helper. This helper has no file side effects.

    switch string(command)
        case "alignByPulseGap"
            [varargout{1:nargout}] = alignByPulseGap(varargin{:});
        case "buildOverlayExportTable"
            varargout{1} = buildOverlayExportTable(varargin{:});
        case "plotVTIT"
            plotVTIT(varargin{:});
        otherwise
            error('labkit:ChronoOverlay:UnknownWorkflowCommand', ...
                'Unknown chrono overlay workflow helper command: %s.', command);
    end
end
function [item, msg] = alignByPulseGap(item)
    t = chronoTime(item);
    if isempty(t)
        error('Chrono item has no time vector.');
    end

    pulseMsg = '';
    if isfield(item, 'pulseMessage')
        pulseMsg = item.pulseMessage;
    elseif isfield(item, 'pulse') && isfield(item.pulse, 'message')
        pulseMsg = item.pulse.message;
    end

    pulse = emptyPulse();
    if isfield(item, 'pulse')
        pulse = item.pulse;
    end

    if isfield(item, 'name')
        itemName = item.name;
    else
        itemName = '';
    end

    if isfield(pulse, 'ok') && pulse.ok
        alignTime = 0.5 * (pulse.gap_start + pulse.gap_end);
        if isfinite(alignTime)
            item.alignTime = alignTime;
            item.tAligned = t - alignTime;
            item.alignTime_s = item.alignTime;
            item.tAligned_s = item.tAligned;
            msg = sprintf('%s: aligned to cathodic/anodic blank center at %.9g s (gap %.9g to %.9g s, %s).', ...
                itemName, alignTime, pulse.gap_start, pulse.gap_end, pulse.method);
            return;
        end

        item.alignTime = t(1);
        item.tAligned = t - item.alignTime;
        item.alignTime_s = item.alignTime;
        item.tAligned_s = item.tAligned;
        msg = sprintf('%s: blank center not found, fallback to first sample (%s).', itemName, pulseMsg);
        return;
    end

    item.alignTime = t(1);
    item.tAligned = t - item.alignTime;
    item.alignTime_s = item.alignTime;
    item.tAligned_s = item.tAligned;
    msg = sprintf('%s: pulse gap not found, fallback to first sample (%s).', itemName, pulseMsg);
end

%% App-local export
function T = buildOverlayExportTable(items)
    timeUnion = [];
    for i = 1:numel(items)
        timeUnion = [timeUnion; chronoAlignedTime(items(i))]; %#ok<AGROW>
    end
    timeUnion = unique(timeUnion);
    timeUnion = sort(timeUnion);

    T = table(timeUnion, 'VariableNames', {'TimeGapCenterAligned_s'});
    for i = 1:numel(items)
        safeName = sanitizeFieldName(items(i).name);
        vName = ['V_' safeName];
        iName = ['I_' safeName];

        tAligned = chronoAlignedTime(items(i));
        Vf = chronoVoltage(items(i));
        Im = chronoCurrent(items(i));
        if numel(tAligned) >= 2
            vData = interp1(tAligned, Vf, timeUnion, 'linear', NaN);
            iData = interp1(tAligned, Im, timeUnion, 'linear', NaN);
        else
            vData = NaN(size(timeUnion));
            iData = NaN(size(timeUnion));
        end

        T.(vName) = vData;
        T.(iName) = iData;
    end
end

%% App-local plotting
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

%% Small app-local utilities
function t = chronoTime(item)
    if isfield(item, 't') && ~isempty(item.t)
        t = item.t;
    elseif isfield(item, 't_s') && ~isempty(item.t_s)
        t = item.t_s;
    else
        t = [];
    end
    t = t(:);
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

function out = sanitizeFieldName(txt)
    out = matlab.lang.makeValidName(txt);
end

function pulse = emptyPulse()
    pulse = struct( ...
        'ok', false, ...
        'method', '-', ...
        'message', '', ...
        'cath_start', NaN, ...
        'cath_end', NaN, ...
        'anod_start', NaN, ...
        'anod_end', NaN, ...
        'Ic_nominal', NaN, ...
        'Ia_nominal', NaN, ...
        'pre_start', NaN, ...
        'pre_end', NaN, ...
        'gap_start', NaN, ...
        'gap_end', NaN, ...
        'post_start', NaN, ...
        'post_end', NaN);

    pulse.cath = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.anod = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.gap = struct('start_s', NaN, 'end_s', NaN, 'center_s', NaN);
end
