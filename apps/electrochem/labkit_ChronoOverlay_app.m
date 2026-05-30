function varargout = labkit_ChronoOverlay_app(varargin)
%LABKIT_CHRONOOVERLAY_APP Chrono voltage/current overlay and export app.
% Single-file app that composes +labkit GUI/DTA APIs and owns overlay workflow choices.

    if nargin > 0
        error('labkit_ChronoOverlay_app:UnsupportedInput', 'labkit_ChronoOverlay_app does not accept input arguments.');
    end
    if nargout > 1
        error('labkit_ChronoOverlay_app:TooManyOutputs', 'labkit_ChronoOverlay_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = labkit.dta.makeSession('chrono_overlay');
    S.items = S.session.items;

    ui = labkit.ui.createTwoPaneShell( ...
        'Gamry Multi-DTA Plot Export GUI', ...
        [80 60 1480 900], ...
        340, ...
        'Overlay Plots', ...
        [2 1], ...
        {'1x', '1x'}, ...
        10);
    fig = ui.fig;
    left = ui.leftGrid;
    right = ui.rightGrid;

    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onRemoveSelected = @onRemoveSelected;
    fileCallbacks.onClearAll = @onClearAll;
    fileCallbacks.onExport = @onExportCSV;
    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'removeSelected', 'Remove selected', ...
        'clearAll', 'Clear all', ...
        'export', 'Export curves CSV');
    labkit.ui.createFilePanel(left, fileLabels, fileCallbacks);

    lbFiles = uilistbox(left, ...
        'Items', {}, ...
        'Multiselect', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    lbFiles.Layout.Row = 2;

    plotOptionsUi = labkit.ui.createPlotOptionsPanel(left, 4);
    gp = plotOptionsUi.grid;

    [~, ddXAxis] = labkit.ui.createLabeledDropdown(gp, 'X axis:', ...
        'Items', {'Time (s)', 'Time (ms)', 'Sample #'}, ...
        'Value', 'Time (s)', ...
        'ValueChangedFcn', @(~,~) refreshPlots());

    [~, edLineWidth] = labkit.ui.createLabeledEditField(gp, 'Line width:', 'numeric', ...
        'Value', 1.3, ...
        'Limits', [0.1 10], ...
        'LowerLimitInclusive', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlots());

    cbLegend = uicheckbox(gp, ...
        'Text', 'Show file-name legend', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    cbLegend.Layout.Row = 3;
    cbLegend.Layout.Column = [1 2];

    cbGrid = uicheckbox(gp, ...
        'Text', 'Show grid', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    cbGrid.Layout.Row = 4;
    cbGrid.Layout.Column = [1 2];

    txtInfo = uitextarea(left, 'Editable', 'off');
    txtInfo.Layout.Row = 4;
    txtInfo.Value = { ...
        'Usage:', ...
        '1. Open multiple .DTA files.', ...
        '2. Curves are aligned to the center of the blank time between cathodic and anodic phases.', ...
        '3. Voltage and current curves will be overlaid.', ...
        '4. Export CSV columns as: TimeGapCenterAligned_s, V_*, I_*.', ...
        '5. If files have different time grids, export uses a merged aligned-time axis with interpolation.' ...
        };

    txtLog = uitextarea(left, 'Editable', 'off');
    txtLog.Layout.Row = 5;
    txtLog.Value = {'GUI started.'};

    axV = labkit.ui.createAxes(right, 1, 'Voltage', 'Time (s)', 'Vf (V)');
    axI = labkit.ui.createAxes(right, 2, 'Current', 'Time (s)', 'Im (A)');
    if nargout == 1
        varargout{1} = fig;
    end

    %% App callbacks, session actions, refresh, and export
    function onOpenFiles(~, ~)
        [f, p] = uigetfile( ...
            {'*.DTA;*.dta', 'Gamry DTA (*.DTA)'; '*.*', 'All files'}, ...
            'Select one or more Gamry DTA files', ...
            'MultiSelect', 'on');
        if isequal(f, 0)
            addLog('Open cancelled.');
            return;
        end

        if ischar(f) || isstring(f)
            f = {char(f)};
        end

        filepaths = cellfun(@(name) fullfile(p, name), f, 'UniformOutput', false);
        loadFiles(filepaths);
    end

    function onOpenFolder(~, ~)
        folder = uigetdir(pwd, 'Select a folder to recursively scan for .DTA files');
        if isequal(folder, 0)
            addLog('Folder selection cancelled.');
            return;
        end

        filepaths = labkit.dta.findFiles(folder);
        if isempty(filepaths)
            addLog(sprintf('No DTA files found under: %s', folder));
            uialert(fig, sprintf('No .DTA files found under:\n%s', folder), 'No files found');
            return;
        end

        addLog(sprintf('Found %d DTA file(s) under %s', numel(filepaths), folder));
        loadFiles(filepaths);
    end

    function loadFiles(filepaths)
        if isempty(filepaths)
            return;
        end

        callbacks = struct();
        callbacks.onAdded = @(~, ~) [];
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));
        [S.session, report] = labkit.dta.addFilesToSession(S.session, filepaths, "chrono", callbacks);
        postProcessAddedItems(report.added);
        S.items = S.session.items;

        refreshFileList();
        refreshPlots();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function postProcessAddedItems(filepaths)
        for iFile = 1:numel(filepaths)
            idx = find(strcmp(string({S.session.items.filepath}), string(filepaths{iFile})), 1, 'first');
            if isempty(idx)
                continue;
            end

            item = S.session.items(idx);
            [item, alignMsg] = alignByPulseGap(item);
            S.session.items(idx) = item;
            addLog(alignMsg);

            for ii = 1:numel(item.logmsg)
                addLog(item.logmsg{ii});
            end
            addLog(sprintf('%s: %s', item.name, item.message));
            addLog(sprintf('Loaded: %s', filepaths{iFile}));
        end
    end

    function onRemoveSelected(~, ~)
        if isempty(S.items) || isempty(lbFiles.Value)
            return;
        end
        callbacks = struct();
        callbacks.onRemoved = @(name, ~) addLog(sprintf('Removed: %s', name));
        [S.session, ~] = labkit.dta.removeSelectedItemsFromSession(S.session, lbFiles.Value, callbacks);
        S.items = S.session.items;
        refreshFileList();
        refreshPlots();
    end

    function onClearAll(~, ~)
        S.session = labkit.dta.makeSession('chrono_overlay');
        S.items = S.session.items;
        refreshFileList();
        refreshPlots();
        addLog('Cleared all files.');
    end

    function refreshFileList()
        if isempty(S.items)
            labkit.ui.refreshListboxItems(lbFiles, {});
            return;
        end
        labkit.ui.refreshListboxItems(lbFiles, {S.items.name});
    end

    function refreshPlots()
        if isempty(S.items)
            plotVTIT(axV, axI, struct([]), plotOptions());
            return;
        end

        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            cla(axV);
            cla(axI);
            return;
        end

        plotVTIT(axV, axI, items, plotOptions());
    end

    function onExportCSV(~, ~)
        if isempty(S.items)
            uialert(fig, 'No files loaded.', 'Export');
            return;
        end

        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_overlay_curves.csv', 'Save overlay curves CSV');
        if isequal(f, 0)
            return;
        end

        T = buildOverlayExportTable(items);
        out = fullfile(p, f);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', out));
    end

    function opts = plotOptions()
        opts = struct();
        opts.xAxis = ddXAxis.Value;
        opts.lineWidth = edLineWidth.Value;
        opts.showGrid = cbGrid.Value;
        opts.showLegend = cbLegend.Value;
    end

    function addLog(msg)
        labkit.ui.appendLog(txtLog, msg);
    end
end

%% App-local analysis
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
