function gamry_multiDTA_plot_export_gui
% GAMRY_MULTIDTA_PLOT_EXPORT_GUI
% Load multiple Gamry .DTA files, overlay voltage/current curves, and
% export aligned curves to CSV.

    S = struct();
    S.items = struct([]);

    fig = uifigure( ...
        'Name', 'Gamry Multi-DTA Plot Export GUI', ...
        'Position', [80 60 1480 900]);

    main = uigridlayout(fig, [1 2]);
    main.ColumnWidth = {340, '1x'};
    main.RowHeight = {'1x'};
    main.Padding = [10 10 10 10];
    main.ColumnSpacing = 10;

    leftPanel = uipanel(main, 'Title', 'Controls');
    leftPanel.Layout.Row = 1;
    leftPanel.Layout.Column = 1;

    left = uigridlayout(leftPanel, [5 1]);
    left.RowHeight = {'fit', '1x', 'fit', 'fit', '1x'};
    left.ColumnWidth = {'1x'};
    left.Padding = [8 8 8 8];
    left.RowSpacing = 10;

    pButtons = uipanel(left, 'Title', 'Files');
    pButtons.Layout.Row = 1;
    gb = uigridlayout(pButtons, [4 2]);
    gb.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    gb.ColumnWidth = {'1x', '1x'};
    gb.Padding = [8 8 8 8];
    gb.RowSpacing = 8;
    gb.ColumnSpacing = 8;

    btnOpen = uibutton(gb, 'Text', 'Open DTA file(s)', 'ButtonPushedFcn', @onOpenFiles);
    btnOpen.Layout.Row = 1;
    btnOpen.Layout.Column = [1 2];

    btnOpenFolder = uibutton(gb, 'Text', 'Open folder recursively', 'ButtonPushedFcn', @onOpenFolder);
    btnOpenFolder.Layout.Row = 2;
    btnOpenFolder.Layout.Column = [1 2];

    btnRemove = uibutton(gb, 'Text', 'Remove selected', 'ButtonPushedFcn', @onRemoveSelected);
    btnRemove.Layout.Row = 3;
    btnRemove.Layout.Column = 1;

    btnClear = uibutton(gb, 'Text', 'Clear all', 'ButtonPushedFcn', @onClearAll);
    btnClear.Layout.Row = 3;
    btnClear.Layout.Column = 2;

    btnExport = uibutton(gb, 'Text', 'Export curves CSV', 'ButtonPushedFcn', @onExportCSV);
    btnExport.Layout.Row = 4;
    btnExport.Layout.Column = [1 2];

    lbFiles = uilistbox(left, ...
        'Items', {}, ...
        'Multiselect', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    lbFiles.Layout.Row = 2;

    pPlot = uipanel(left, 'Title', 'Plot Options');
    pPlot.Layout.Row = 3;
    gp = uigridlayout(pPlot, [4 2]);
    gp.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    gp.ColumnWidth = {'fit', '1x'};
    gp.Padding = [8 8 8 8];
    gp.RowSpacing = 8;
    gp.ColumnSpacing = 8;

    uilabel(gp, 'Text', 'X axis:', 'HorizontalAlignment', 'right');
    ddXAxis = uidropdown(gp, ...
        'Items', {'Time (s)', 'Time (ms)', 'Sample #'}, ...
        'Value', 'Time (s)', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    ddXAxis.Layout.Row = 1;
    ddXAxis.Layout.Column = 2;

    uilabel(gp, 'Text', 'Line width:', 'HorizontalAlignment', 'right');
    edLineWidth = uieditfield(gp, 'numeric', ...
        'Value', 1.3, ...
        'Limits', [0.1 10], ...
        'LowerLimitInclusive', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    edLineWidth.Layout.Row = 2;
    edLineWidth.Layout.Column = 2;

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

    rightPanel = uipanel(main, 'Title', 'Overlay Plots');
    rightPanel.Layout.Row = 1;
    rightPanel.Layout.Column = 2;

    right = uigridlayout(rightPanel, [2 1]);
    right.RowHeight = {'1x', '1x'};
    right.ColumnWidth = {'1x'};
    right.Padding = [8 8 8 8];
    right.RowSpacing = 10;

    axV = uiaxes(right);
    axV.Layout.Row = 1;
    title(axV, 'Voltage');
    xlabel(axV, 'Time (s)');
    ylabel(axV, 'Vf (V)');

    axI = uiaxes(right);
    axI.Layout.Row = 2;
    title(axI, 'Current');
    xlabel(axI, 'Time (s)');
    ylabel(axI, 'Im (A)');

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

        filepaths = findDTAFilesRecursive(folder);
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

        filepaths = unique(filepaths, 'stable');
        if isempty(S.items) || ~isfield(S.items, 'filepath')
            existing = strings(0, 1);
        else
            existing = string({S.items.filepath});
        end
        queued = string(filepaths);
        if ~isempty(existing)
            isNew = ~ismember(queued, existing);
            skipped = filepaths(~isNew);
            filepaths = filepaths(isNew);
            for i = 1:numel(skipped)
                addLog(sprintf('Skipped already loaded: %s', skipped{i}));
            end
        end

        if isempty(filepaths)
            refreshFileList();
            refreshPlots();
            return;
        end

        firstError = [];
        for k = 1:numel(filepaths)
            filepath = filepaths{k};
            try
                item = loadOneDTA(filepath);
                S.items = appendStruct(S.items, item);
                addLog(sprintf('Loaded: %s', filepath));
            catch ME
                addLog(sprintf('Failed: %s | %s', filepath, ME.message));
                if isempty(firstError)
                    firstError = struct('filepath', filepath, 'message', ME.message);
                end
            end
        end

        refreshFileList();
        refreshPlots();

        if ~isempty(firstError)
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function item = loadOneDTA(filepath)
        item = struct();
        item.filepath = filepath;
        item.name = shortName(filepath);
        [item.meta, item.tables, item.logmsg] = parseGamryChronoDTA(filepath);

        [curve, ok, msg] = getMainCurve(item.tables);
        if ~ok
            error('%s', msg);
        end

        t = getColByName(curve, 'T');
        Vf = getColByName(curve, 'Vf');
        Im = getColByName(curve, 'Im');
        pt = getColByName(curve, 'Pt');
        if isempty(pt)
            pt = (0:numel(t)-1).';
        end

        valid = isfinite(t) & isfinite(Vf) & isfinite(Im);
        t = t(valid);
        Vf = Vf(valid);
        Im = Im(valid);
        pt = pt(valid);

        if numel(t) < 2
            error('Not enough valid T/Vf/Im data points.');
        end

        [t, ia] = unique(t, 'stable');
        Vf = Vf(ia);
        Im = Im(ia);
        pt = pt(ia);

        item.curve = curve;
        item.t = t(:);
        item.Vf = Vf(:);
        item.Im = Im(:);
        item.pt = pt(:);
        item.n = numel(t);
        item.message = msg;
        [item.pulse, pulseMsg] = detectPulses(item.meta, item.t, item.Im);
        item.pulseMessage = pulseMsg;
        if item.pulse.ok
            alignTime = 0.5 * (item.pulse.gap_start + item.pulse.gap_end);
            if isfinite(alignTime)
                item.alignTime = alignTime;
                item.tAligned = item.t - alignTime;
                addLog(sprintf('%s: aligned to cathodic/anodic blank center at %.9g s (gap %.9g to %.9g s, %s).', ...
                    item.name, alignTime, item.pulse.gap_start, item.pulse.gap_end, item.pulse.method));
            else
                item.alignTime = item.t(1);
                item.tAligned = item.t - item.alignTime;
                addLog(sprintf('%s: blank center not found, fallback to first sample (%s).', ...
                    item.name, pulseMsg));
            end
        else
            item.alignTime = item.t(1);
            item.tAligned = item.t - item.alignTime;
            addLog(sprintf('%s: pulse gap not found, fallback to first sample (%s).', ...
                item.name, pulseMsg));
        end

        for ii = 1:numel(item.logmsg)
            addLog(item.logmsg{ii});
        end
        addLog(sprintf('%s: %s', item.name, msg));
    end

    function onRemoveSelected(~, ~)
        if isempty(S.items) || isempty(lbFiles.Value)
            return;
        end
        names = string(lbFiles.Value);
        keep = true(1, numel(S.items));
        for i = 1:numel(S.items)
            if any(names == string(S.items(i).name))
                keep(i) = false;
                addLog(sprintf('Removed: %s', S.items(i).name));
            end
        end
        S.items = S.items(keep);
        refreshFileList();
        refreshPlots();
    end

    function onClearAll(~, ~)
        S.items = struct([]);
        refreshFileList();
        refreshPlots();
        addLog('Cleared all files.');
    end

    function refreshFileList()
        if isempty(S.items)
            lbFiles.Items = {};
            lbFiles.Value = {};
            return;
        end
        names = {S.items.name};
        lbFiles.Items = names;
        if isempty(lbFiles.Value)
            lbFiles.Value = names;
        else
            existing = string(lbFiles.Value);
            valid = ismember(existing, string(names));
            selected = cellstr(existing(valid));
            if isempty(selected)
                lbFiles.Value = names;
            else
                lbFiles.Value = selected;
            end
        end
    end

    function refreshPlots()
        cla(axV);
        cla(axI);

        if isempty(S.items)
            title(axV, 'Voltage');
            title(axI, 'Current');
            xlabel(axV, 'Blank-Center Aligned Time (s)');
            xlabel(axI, 'Blank-Center Aligned Time (s)');
            ylabel(axV, 'Vf (V)');
            ylabel(axI, 'Im (A)');
            return;
        end

        selectedNames = string(lbFiles.Value);
        if isempty(selectedNames)
            selectedMask = true(1, numel(S.items));
        else
            selectedMask = false(1, numel(S.items));
            for i = 1:numel(S.items)
                selectedMask(i) = any(selectedNames == string(S.items(i).name));
            end
        end

        idx = find(selectedMask);
        if isempty(idx)
            return;
        end

        cmap = lines(numel(idx));
        hold(axV, 'on');
        hold(axI, 'on');

        labels = cell(1, numel(idx));
        for k = 1:numel(idx)
            item = S.items(idx(k));
            x = chooseX(item, ddXAxis.Value);
            plot(axV, x, item.Vf, 'LineWidth', edLineWidth.Value, 'Color', cmap(k, :));
            plot(axI, x, item.Im, 'LineWidth', edLineWidth.Value, 'Color', cmap(k, :));
            labels{k} = item.name;
        end

        hold(axV, 'off');
        hold(axI, 'off');

        xlabelText = axisLabel(ddXAxis.Value);
        xlabel(axV, xlabelText);
        xlabel(axI, xlabelText);
        ylabel(axV, 'Vf (V)');
        ylabel(axI, 'Im (A)');
        title(axV, sprintf('Voltage Overlay (%d file%s)', numel(idx), ternary(numel(idx) == 1, '', 's')));
        title(axI, sprintf('Current Overlay (%d file%s)', numel(idx), ternary(numel(idx) == 1, '', 's')));

        if cbGrid.Value
            grid(axV, 'on');
            grid(axI, 'on');
        else
            grid(axV, 'off');
            grid(axI, 'off');
        end

        if cbLegend.Value
            legend(axV, labels, 'Interpreter', 'none', 'Location', 'best');
            legend(axI, labels, 'Interpreter', 'none', 'Location', 'best');
        else
            legend(axV, 'off');
            legend(axI, 'off');
        end
    end

    function onExportCSV(~, ~)
        if isempty(S.items)
            uialert(fig, 'No files loaded.', 'Export');
            return;
        end

        selectedNames = string(lbFiles.Value);
        if isempty(selectedNames)
            idx = 1:numel(S.items);
        else
            idx = find(ismember(string({S.items.name}), selectedNames));
        end

        if isempty(idx)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_overlay_curves.csv', 'Save overlay curves CSV');
        if isequal(f, 0)
            return;
        end

        items = S.items(idx);
        T = buildExportTable(items);
        out = fullfile(p, f);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', out));
    end

    function T = buildExportTable(items)
        timeUnion = [];
        for i = 1:numel(items)
            timeUnion = [timeUnion; items(i).tAligned(:)]; %#ok<AGROW>
        end
        timeUnion = unique(timeUnion);
        timeUnion = sort(timeUnion);

        T = table(timeUnion, 'VariableNames', {'TimeGapCenterAligned_s'});
        for i = 1:numel(items)
            safeName = matlab.lang.makeValidName(items(i).name);
            vName = ['V_' safeName];
            iName = ['I_' safeName];

            if numel(items(i).tAligned) >= 2
                vData = interp1(items(i).tAligned, items(i).Vf, timeUnion, 'linear', NaN);
                iData = interp1(items(i).tAligned, items(i).Im, timeUnion, 'linear', NaN);
            else
                vData = NaN(size(timeUnion));
                iData = NaN(size(timeUnion));
            end

            T.(vName) = vData;
            T.(iName) = iData;
        end
    end

    function x = chooseX(item, mode)
        switch mode
            case 'Time (ms)'
                x = 1e3 * item.tAligned;
            case 'Sample #'
                x = item.pt;
            otherwise
                x = item.tAligned;
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

    function addLog(msg)
        ts = datestr(now, 'HH:MM:SS');
        old = txtLog.Value;
        old{end+1} = sprintf('[%s] %s', ts, char(msg));
        txtLog.Value = old;
        drawnow limitrate
    end
end

function [pulse, msg] = detectPulses(meta, t, Im)
    [pulse, okM, msgM] = pulsesFromMetadata(meta, t);
    if okM
        msg = msgM;
        return;
    end

    [pulse, okA, msgA] = pulsesFromCurrent(t, Im);
    if okA
        msg = sprintf('%s | fallback success: %s', msgM, msgA);
    else
        msg = sprintf('%s | %s', msgM, msgA);
    end
end

function [pulse, ok, msg] = pulsesFromMetadata(meta, t)
    pulse = emptyPulse();
    ok = false;

    if isempty(meta) || ~isfield(meta, 'steps') || isempty(meta.steps)
        msg = 'Metadata pulse detection: no ISTEP/TSTEP or VSTEP/TSTEP steps found.';
        return;
    end

    steps = meta.steps;
    Ivals = [steps.I];
    Vvals = [steps.V];
    Tvals = [steps.T];
    if all(~isfinite(Tvals))
        msg = 'Metadata pulse detection: invalid step values.';
        return;
    end

    stepMode = '';
    stepVals = [];
    if any(isfinite(Ivals))
        stepVals = Ivals;
        stepMode = 'current';
    elseif any(isfinite(Vvals))
        stepVals = Vvals;
        stepMode = 'voltage';
    else
        msg = 'Metadata pulse detection: neither current nor voltage step values were found.';
        return;
    end

    [minStep, idxCath] = min(stepVals);
    [maxStep, idxAnod] = max(stepVals);
    if ~isfinite(minStep) || ~isfinite(maxStep) || minStep >= 0 || maxStep <= 0
        msg = sprintf('Metadata pulse detection: could not find both negative and positive %s steps.', stepMode);
        return;
    end

    if idxAnod < idxCath
        msg = sprintf('Metadata pulse detection: positive %s step appears before negative step.', stepMode);
        return;
    end

    t0 = 0;
    starts = zeros(size(Tvals));
    ends = zeros(size(Tvals));
    for k = 1:numel(Tvals)
        starts(k) = t0;
        ends(k) = t0 + Tvals(k);
        t0 = ends(k);
    end

    pulse.ok = true;
    pulse.method = ['metadata-' stepMode];
    pulse.cath_start = starts(idxCath);
    pulse.cath_end = ends(idxCath);
    pulse.anod_start = starts(idxAnod);
    pulse.anod_end = ends(idxAnod);
    if strcmp(stepMode, 'current')
        pulse.Ic_nominal = Ivals(idxCath);
        pulse.Ia_nominal = Ivals(idxAnod);
    else
        pulse.Ic_nominal = NaN;
        pulse.Ia_nominal = NaN;
    end

    if idxCath > 1
        pulse.pre_start = starts(idxCath - 1);
        pulse.pre_end = ends(idxCath - 1);
    else
        pulse.pre_start = t(1);
        pulse.pre_end = pulse.cath_start;
    end

    if idxAnod > idxCath
        pulse.gap_start = pulse.cath_end;
        pulse.gap_end = pulse.anod_start;
    else
        pulse.gap_start = pulse.cath_end;
        pulse.gap_end = pulse.cath_end;
    end

    if idxAnod < numel(Tvals)
        pulse.post_start = starts(idxAnod + 1);
        pulse.post_end = ends(idxAnod + 1);
    else
        pulse.post_start = pulse.anod_end;
        pulse.post_end = t(end);
    end

    ok = true;
    msg = sprintf('Metadata pulse detection OK (%s-controlled): cath step %d, anod step %d.', ...
        stepMode, idxCath, idxAnod);
end

function [pulse, ok, msg] = pulsesFromCurrent(t, Im)
    pulse = emptyPulse();
    ok = false;

    Iabs = abs(Im);
    thr = max(1e-12, 0.25 * max(Iabs));
    cathMask = Im <= -thr;
    anodMask = Im >= thr;

    cathSeg = contiguousSegments(cathMask);
    anodSeg = contiguousSegments(anodMask);

    if isempty(cathSeg) || isempty(anodSeg)
        msg = 'Auto pulse detection: could not find both cathodic and anodic segments.';
        return;
    end

    cathLen = cathSeg(:, 2) - cathSeg(:, 1) + 1;
    [~, ic] = max(cathLen);
    cseg = cathSeg(ic, :);

    asegCandidates = anodSeg(anodSeg(:, 1) > cseg(2), :);
    if isempty(asegCandidates)
        msg = 'Auto pulse detection: found cathodic segment but no later anodic segment.';
        return;
    end

    anodLen = asegCandidates(:, 2) - asegCandidates(:, 1) + 1;
    [~, ia] = max(anodLen);
    aseg = asegCandidates(ia, :);

    pulse.ok = true;
    pulse.method = 'auto-from-Im';
    pulse.cath_start = t(cseg(1));
    pulse.cath_end = t(cseg(2));
    pulse.anod_start = t(aseg(1));
    pulse.anod_end = t(aseg(2));
    pulse.Ic_nominal = median(Im(cseg(1):cseg(2)), 'omitnan');
    pulse.Ia_nominal = median(Im(aseg(1):aseg(2)), 'omitnan');
    pulse.pre_start = t(1);
    pulse.pre_end = pulse.cath_start;
    pulse.gap_start = pulse.cath_end;
    pulse.gap_end = pulse.anod_start;
    pulse.post_start = pulse.anod_end;
    pulse.post_end = t(end);

    ok = true;
    msg = sprintf('Auto pulse detection OK: cath [%d %d], anod [%d %d].', cseg(1), cseg(2), aseg(1), aseg(2));
end

function pulse = emptyPulse()
    pulse = struct( ...
        'ok', false, ...
        'method', '-', ...
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
end

function seg = contiguousSegments(mask)
    mask = mask(:).';
    d = diff([false, mask, false]);
    starts = find(d == 1);
    ends = find(d == -1) - 1;
    seg = [starts(:), ends(:)];
end

function filepaths = findDTAFilesRecursive(rootDir)
    entries = dir(rootDir);
    filepaths = {};

    for i = 1:numel(entries)
        name = entries(i).name;
        if strcmp(name, '.') || strcmp(name, '..')
            continue;
        end

        fullpath = fullfile(entries(i).folder, name);
        if entries(i).isdir
            subpaths = findDTAFilesRecursive(fullpath);
            if ~isempty(subpaths)
                filepaths = [filepaths, subpaths]; %#ok<AGROW>
            end
        else
            [~, ~, ext] = fileparts(name);
            if strcmpi(ext, '.dta')
                filepaths{end+1} = fullpath; %#ok<AGROW>
            end
        end
    end
end

function [meta, tables, logmsg] = parseGamryChronoDTA(filepath)
    txt = fileread(filepath);
    txt = erase(txt, char(13));
    lines = splitlines(string(txt));
    lines = cellstr(lines);

    meta = struct();
    meta.filepath = filepath;
    meta.area_cm2 = NaN;
    meta.sampleTime_s = NaN;
    meta.steps = struct('idx', {}, 'I', {}, 'V', {}, 'T', {});
    tables = struct('name', {}, 'headers', {}, 'units', {}, 'data', {}, 'numericMask', {});
    logmsg = {};

    nLines = numel(lines);
    logmsg{end+1} = sprintf('Parsing DTA: %s', filepath);

    stepI = containers.Map('KeyType', 'int32', 'ValueType', 'double');
    stepV = containers.Map('KeyType', 'int32', 'ValueType', 'double');
    stepT = containers.Map('KeyType', 'int32', 'ValueType', 'double');

    for i = 1:nLines
        tok = splitTabs(lines{i});
        if numel(tok) < 3
            continue;
        end
        key = strtrim(tok{1});
        valueStr = tok{3};
        valueNum = str2double(valueStr);

        switch upper(key)
            case 'AREA'
                if isfinite(valueNum)
                    meta.area_cm2 = valueNum;
                end
            case 'SAMPLETIME'
                if isfinite(valueNum)
                    meta.sampleTime_s = valueNum;
                end
        end

        rI = regexp(key, '^ISTEP(\d+)$', 'tokens', 'once');
        if ~isempty(rI)
            idx = int32(str2double(rI{1}));
            if isfinite(valueNum)
                stepI(idx) = valueNum;
            end
        end

        rV = regexp(key, '^VSTEP(\d+)$', 'tokens', 'once');
        if ~isempty(rV)
            idx = int32(str2double(rV{1}));
            if isfinite(valueNum)
                stepV(idx) = valueNum;
            end
        end

        rT = regexp(key, '^TSTEP(\d+)$', 'tokens', 'once');
        if ~isempty(rT)
            idx = int32(str2double(rT{1}));
            if isfinite(valueNum)
                stepT(idx) = valueNum;
            end
        end
    end

    allIdx = unique([cell2mat(keys(stepI)), cell2mat(keys(stepV)), cell2mat(keys(stepT))]);
    allIdx = sort(allIdx);
    for k = 1:numel(allIdx)
        idx = allIdx(k);
        I = NaN;
        V = NaN;
        T = NaN;
        if isKey(stepI, idx)
            I = stepI(idx);
        end
        if isKey(stepV, idx)
            V = stepV(idx);
        end
        if isKey(stepT, idx)
            T = stepT(idx);
        end
        meta.steps(end+1) = struct('idx', double(idx), 'I', I, 'V', V, 'T', T); %#ok<AGROW>
    end

    if ~isempty(meta.steps)
        if any(isfinite([meta.steps.I]))
            logmsg{end+1} = sprintf('Found %d ISTEP/TSTEP step(s).', numel(meta.steps));
        elseif any(isfinite([meta.steps.V]))
            logmsg{end+1} = sprintf('Found %d VSTEP/TSTEP step(s).', numel(meta.steps));
        else
            logmsg{end+1} = sprintf('Found %d step(s) with timing only.', numel(meta.steps));
        end
    else
        logmsg{end+1} = 'No ISTEP/TSTEP or VSTEP/TSTEP sequence found.';
    end

    i = 1;
    while i <= nLines
        tok = splitTabs(lines{i});
        if numel(tok) >= 3 && strcmpi(tok{2}, 'TABLE')
            name = tok{1};
            iHeader = nextNonEmpty(lines, i + 1);
            iUnits = nextNonEmpty(lines, iHeader + 1);
            if isnan(iHeader) || isnan(iUnits)
                i = i + 1;
                continue;
            end

            headers = splitTabs(lines{iHeader});
            units = splitTabs(lines{iUnits});
            if isDataLike(units)
                dataStart = iUnits;
                units = repmat({''}, size(headers));
            else
                dataStart = nextNonEmpty(lines, iUnits + 1);
            end

            raw = [];
            j = dataStart;
            while j <= nLines
                tokj = splitTabs(lines{j});
                if isempty(tokj)
                    j = j + 1;
                    continue;
                end
                if numel(tokj) >= 3 && strcmpi(tokj{2}, 'TABLE')
                    break;
                end
                row = nan(1, numel(headers));
                nKeep = min(numel(tokj), numel(headers));
                anyNumeric = false;
                for c = 1:nKeep
                    v = str2double(tokj{c});
                    if ~isnan(v)
                        row(c) = v;
                        anyNumeric = true;
                    end
                end
                if anyNumeric
                    raw(end+1, :) = row; %#ok<AGROW>
                end
                j = j + 1;
            end

            if ~isempty(raw)
                numericMask = any(~isnan(raw), 1);
                tables(end+1).name = name; %#ok<AGROW>
                tables(end).headers = headers;
                tables(end).units = units;
                tables(end).data = raw;
                tables(end).numericMask = numericMask;
                logmsg{end+1} = sprintf('Table %s parsed: %d rows x %d cols.', name, size(raw, 1), size(raw, 2));
            else
                logmsg{end+1} = sprintf('Table %s found but no numeric rows.', name);
            end

            i = j;
        else
            i = i + 1;
        end
    end

    if isempty(tables)
        error('No numeric TABLE section was parsed from this DTA file.');
    end
end

function [curve, ok, msg] = getMainCurve(tables)
    ok = false;
    msg = 'Main transient table not found.';
    curve = struct();
    if isempty(tables)
        return;
    end

    idxMain = [];
    for i = 1:numel(tables)
        nm = lower(strtrim(tables(i).name));
        if strcmp(nm, 'curve') || strcmp(nm, 'curve1')
            idxMain = i;
            break;
        end
    end
    if isempty(idxMain)
        for i = 1:numel(tables)
            h = lower(tables(i).headers);
            if any(strcmp(h, 't')) && any(strcmp(h, 'vf')) && any(strcmp(h, 'im'))
                idxMain = i;
                break;
            end
        end
    end
    if isempty(idxMain)
        return;
    end

    curve = tables(idxMain);
    ok = true;
    msg = sprintf('Using table: %s', curve.name);
end

function out = appendStruct(S, item)
    if isempty(S)
        out = item;
    else
        out = [S, item];
    end
end

function name = shortName(filepath)
    [~, name, ext] = fileparts(filepath);
    name = [name ext];
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end

function tok = splitTabs(line)
    tok = regexp(char(line), '\t+', 'split');
    tok = tok(~cellfun(@isempty, tok));
end

function idx = nextNonEmpty(lines, startIdx)
    idx = NaN;
    for i = startIdx:numel(lines)
        if ~isempty(strtrim(lines{i}))
            idx = i;
            return;
        end
    end
end

function tf = isDataLike(tok)
    if isempty(tok)
        tf = false;
        return;
    end
    vals = nan(size(tok));
    for i = 1:numel(tok)
        vals(i) = str2double(tok{i});
    end
    tf = any(~isnan(vals));
end

function col = getColByName(tbl, name)
    idx = find(strcmpi(tbl.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = tbl.data(:, idx);
    end
end
