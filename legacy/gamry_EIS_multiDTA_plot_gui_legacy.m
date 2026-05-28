function gamry_EIS_multiDTA_plot_gui_legacy
% GAMRY_EIS_MULTIDTA_PLOT_GUI
% Load one or more Gamry EIS .DTA files, select arbitrary X/Y axes from
% ZCURVE columns, overlay curves, and export the currently selected data.

    S = struct();
    S.items = struct([]);

    axisItems = { ...
        'Freq (Hz)', ...
        'log10(Freq)', ...
        'Time (s)', ...
        'Point #', ...
        'Zreal (ohm)', ...
        'Zimag (ohm)', ...
        '-Zimag (ohm)', ...
        'Zmod (ohm)', ...
        'Zphz (deg)', ...
        'Idc (A)', ...
        'Vdc (V)'};

    fig = uifigure( ...
        'Name', 'Gamry EIS Multi-DTA Plot GUI', ...
        'Position', [80 60 1500 900]);

    main = uigridlayout(fig, [1 2]);
    main.ColumnWidth = {360, '1x'};
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

    pFiles = uipanel(left, 'Title', 'Files');
    pFiles.Layout.Row = 1;
    gf = uigridlayout(pFiles, [4 2]);
    gf.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    gf.ColumnWidth = {'1x', '1x'};
    gf.Padding = [8 8 8 8];
    gf.RowSpacing = 8;
    gf.ColumnSpacing = 8;

    btnOpen = uibutton(gf, 'Text', 'Open DTA file(s)', 'ButtonPushedFcn', @onOpenFiles);
    btnOpen.Layout.Row = 1;
    btnOpen.Layout.Column = [1 2];

    btnOpenFolder = uibutton(gf, 'Text', 'Open folder recursively', 'ButtonPushedFcn', @onOpenFolder);
    btnOpenFolder.Layout.Row = 2;
    btnOpenFolder.Layout.Column = [1 2];

    btnRemove = uibutton(gf, 'Text', 'Remove selected', 'ButtonPushedFcn', @onRemoveSelected);
    btnRemove.Layout.Row = 3;
    btnRemove.Layout.Column = 1;

    btnClear = uibutton(gf, 'Text', 'Clear all', 'ButtonPushedFcn', @onClearAll);
    btnClear.Layout.Row = 3;
    btnClear.Layout.Column = 2;

    btnExport = uibutton(gf, 'Text', 'Export current plot CSV', 'ButtonPushedFcn', @onExportCSV);
    btnExport.Layout.Row = 4;
    btnExport.Layout.Column = [1 2];

    lbFiles = uilistbox(left, ...
        'Items', {}, ...
        'Multiselect', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    lbFiles.Layout.Row = 2;

    pPlot = uipanel(left, 'Title', 'Plot Options');
    pPlot.Layout.Row = 3;
    gp = uigridlayout(pPlot, [8 2]);
    gp.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
    gp.ColumnWidth = {'fit', '1x'};
    gp.Padding = [8 8 8 8];
    gp.RowSpacing = 8;
    gp.ColumnSpacing = 8;

    uilabel(gp, 'Text', 'X axis:', 'HorizontalAlignment', 'right');
    ddX = uidropdown(gp, ...
        'Items', axisItems, ...
        'Value', 'Zreal (ohm)', ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    ddX.Layout.Row = 1;
    ddX.Layout.Column = 2;

    uilabel(gp, 'Text', 'Y axis:', 'HorizontalAlignment', 'right');
    ddY = uidropdown(gp, ...
        'Items', axisItems, ...
        'Value', '-Zimag (ohm)', ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    ddY.Layout.Row = 2;
    ddY.Layout.Column = 2;

    uilabel(gp, 'Text', 'Line width:', 'HorizontalAlignment', 'right');
    edLineWidth = uieditfield(gp, 'numeric', ...
        'Value', 1.4, ...
        'Limits', [0.1 10], ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    edLineWidth.Layout.Row = 3;
    edLineWidth.Layout.Column = 2;

    uilabel(gp, 'Text', 'Marker size:', 'HorizontalAlignment', 'right');
    edMarkerSize = uieditfield(gp, 'numeric', ...
        'Value', 6, ...
        'Limits', [1 20], ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    edMarkerSize.Layout.Row = 4;
    edMarkerSize.Layout.Column = 2;

    cbMarkers = uicheckbox(gp, ...
        'Text', 'Show markers', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbMarkers.Layout.Row = 5;
    cbMarkers.Layout.Column = [1 2];

    cbLogX = uicheckbox(gp, ...
        'Text', 'Log X', ...
        'Value', false, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbLogX.Layout.Row = 6;
    cbLogX.Layout.Column = [1 2];

    cbLogY = uicheckbox(gp, ...
        'Text', 'Log Y', ...
        'Value', false, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbLogY.Layout.Row = 7;
    cbLogY.Layout.Column = [1 2];

    row8 = uigridlayout(gp, [1 2]);
    row8.Layout.Row = 8;
    row8.Layout.Column = [1 2];
    row8.ColumnWidth = {'1x', '1x'};
    row8.RowHeight = {'fit'};
    row8.Padding = [0 0 0 0];
    row8.ColumnSpacing = 8;

    cbLegend = uicheckbox(row8, ...
        'Text', 'Legend', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbGrid = uicheckbox(row8, ...
        'Text', 'Grid', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    txtInfo = uitextarea(left, 'Editable', 'off');
    txtInfo.Layout.Row = 4;
    txtInfo.Value = { ...
        'Usage:', ...
        '1. Open one or more EIS .DTA files containing ZCURVE.', ...
        '2. Choose any X and Y axis combination.', ...
        '3. Use Zreal vs -Zimag for a Nyquist plot.', ...
        '4. Use Freq vs Zmod or Zphz for Bode-style plots.', ...
        '5. CSV export writes one shared row index with X/Y pairs per file.'};

    txtLog = uitextarea(left, 'Editable', 'off');
    txtLog.Layout.Row = 5;
    txtLog.Value = {'GUI started.'};

    rightPanel = uipanel(main, 'Title', 'Plot');
    rightPanel.Layout.Row = 1;
    rightPanel.Layout.Column = 2;

    right = uigridlayout(rightPanel, [2 1]);
    right.RowHeight = {'1x', 'fit'};
    right.ColumnWidth = {'1x'};
    right.Padding = [8 8 8 8];
    right.RowSpacing = 8;

    ax = uiaxes(right);
    ax.Layout.Row = 1;
    title(ax, 'EIS Overlay');
    xlabel(ax, 'Zreal (ohm)');
    ylabel(ax, '-Zimag (ohm)');

    txtSummary = uitextarea(right, 'Editable', 'off');
    txtSummary.Layout.Row = 2;
    txtSummary.Value = {'No files loaded.'};

    function onOpenFiles(~, ~)
        [f, p] = uigetfile( ...
            {'*.DTA;*.dta', 'Gamry DTA (*.DTA)'; '*.*', 'All files'}, ...
            'Select one or more Gamry EIS DTA files', ...
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
        existing = strings(0, 1);
        if ~isempty(S.items) && isfield(S.items, 'filepath')
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
        refreshPlot();

        if ~isempty(firstError)
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function item = loadOneDTA(filepath)
        item = struct();
        item.filepath = filepath;
        item.name = shortName(filepath);
        [item.meta, item.tables, item.logmsg] = parseGamryDTA(filepath);

        [curve, ok, msg] = getZCurve(item.tables);
        if ~ok
            error('%s', msg);
        end

        item.curve = curve;
        item.Pt = defaultColumn(curve, 'Pt');
        item.Time = defaultColumn(curve, 'Time');
        item.Freq = defaultColumn(curve, 'Freq');
        item.Zreal = defaultColumn(curve, 'Zreal');
        item.Zimag = defaultColumn(curve, 'Zimag');
        item.Zmod = defaultColumn(curve, 'Zmod');
        item.Zphz = defaultColumn(curve, 'Zphz');
        item.Idc = defaultColumn(curve, 'Idc');
        item.Vdc = defaultColumn(curve, 'Vdc');
        item.negZimag = -item.Zimag;

        valid = isfinite(item.Freq) | isfinite(item.Zreal) | isfinite(item.Zimag) | isfinite(item.Zmod) | isfinite(item.Zphz);
        fields = {'Pt', 'Time', 'Freq', 'Zreal', 'Zimag', 'negZimag', 'Zmod', 'Zphz', 'Idc', 'Vdc'};
        for ii = 1:numel(fields)
            item.(fields{ii}) = item.(fields{ii})(valid);
        end

        if numel(item.Pt) < 2
            error('Not enough valid ZCURVE points.');
        end

        if isempty(item.Pt) || all(~isfinite(item.Pt))
            item.Pt = (0:numel(item.Freq)-1).';
        end

        item.n = numel(item.Pt);
        item.freqDesc = isMostlyDescending(item.Freq);
        item.message = msg;

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
        refreshPlot();
    end

    function onClearAll(~, ~)
        S.items = struct([]);
        refreshFileList();
        refreshPlot();
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
            return;
        end

        current = string(lbFiles.Value);
        valid = ismember(current, string(names));
        selected = cellstr(current(valid));
        if isempty(selected)
            lbFiles.Value = names;
        else
            lbFiles.Value = selected;
        end
    end

    function refreshPlot()
        cla(ax);
        ax.XScale = ternary(cbLogX.Value, 'log', 'linear');
        ax.YScale = ternary(cbLogY.Value, 'log', 'linear');
        axis(ax, 'normal');

        if isempty(S.items)
            title(ax, 'EIS Overlay');
            xlabel(ax, labelForAxis(ddX.Value));
            ylabel(ax, labelForAxis(ddY.Value));
            txtSummary.Value = {'No files loaded.'};
            return;
        end

        items = getSelectedItems();
        if isempty(items)
            txtSummary.Value = {'No files selected.'};
            return;
        end

        cmap = lines(numel(items));
        labels = cell(1, numel(items));
        marker = 'none';
        if cbMarkers.Value
            marker = 'o';
        end

        hold(ax, 'on');
        for k = 1:numel(items)
            x = valuesForAxis(items(k), ddX.Value);
            y = valuesForAxis(items(k), ddY.Value);
            valid = isfinite(x) & isfinite(y);
            x = x(valid);
            y = y(valid);

            if cbLogX.Value
                validX = x > 0;
                x = x(validX);
                y = y(validX);
            end
            if cbLogY.Value
                validY = y > 0;
                x = x(validY);
                y = y(validY);
            end

            plot(ax, x, y, ...
                'LineWidth', edLineWidth.Value, ...
                'Marker', marker, ...
                'MarkerSize', edMarkerSize.Value, ...
                'Color', cmap(k, :));
            labels{k} = items(k).name;
        end
        hold(ax, 'off');

        xlabel(ax, labelForAxis(ddX.Value));
        ylabel(ax, labelForAxis(ddY.Value));
        title(ax, sprintf('%s vs %s (%d file%s)', ...
            labelForAxis(ddY.Value), labelForAxis(ddX.Value), numel(items), pluralS(numel(items))));

        if cbGrid.Value
            grid(ax, 'on');
        else
            grid(ax, 'off');
        end

        if cbLegend.Value
            legend(ax, labels, 'Interpreter', 'none', 'Location', 'best');
        else
            legend(ax, 'off');
        end

        if isNyquistSelection(ddX.Value, ddY.Value)
            axis(ax, 'equal');
        end

        txtSummary.Value = buildSummary(items);
    end

    function items = getSelectedItems()
        if isempty(S.items)
            items = struct([]);
            return;
        end

        names = string(lbFiles.Value);
        if isempty(names)
            items = S.items;
            return;
        end

        mask = ismember(string({S.items.name}), names);
        items = S.items(mask);
    end

    function onExportCSV(~, ~)
        items = getSelectedItems();
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_eis_plot_export.csv', 'Save current X/Y plot CSV');
        if isequal(f, 0)
            return;
        end

        T = buildExportTable(items, ddX.Value, ddY.Value, cbLogX.Value, cbLogY.Value);
        out = fullfile(p, f);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', out));
    end

    function T = buildExportTable(items, xName, yName, useLogX, useLogY)
        maxLen = 0;
        xCell = cell(1, numel(items));
        yCell = cell(1, numel(items));

        for i = 1:numel(items)
            x = valuesForAxis(items(i), xName);
            y = valuesForAxis(items(i), yName);
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
            xCell{i} = x(:);
            yCell{i} = y(:);
            maxLen = max(maxLen, numel(x));
        end

        T = table((1:maxLen).', 'VariableNames', {'RowIndex'});
        for i = 1:numel(items)
            safeName = matlab.lang.makeValidName(items(i).name);
            xVar = matlab.lang.makeValidName(sprintf('X_%s_%s', sanitizeAxisName(xName), safeName));
            yVar = matlab.lang.makeValidName(sprintf('Y_%s_%s', sanitizeAxisName(yName), safeName));
            xData = padWithNaN(xCell{i}, maxLen);
            yData = padWithNaN(yCell{i}, maxLen);
            T.(xVar) = xData;
            T.(yVar) = yData;
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

function [meta, tables, logmsg] = parseGamryDTA(filepath)
    txt = fileread(filepath);
    txt = erase(txt, char(13));
    lines = splitlines(string(txt));
    lines = cellstr(lines);

    meta = struct();
    meta.filepath = filepath;
    meta.tag = '';
    meta.title = '';
    meta.area_cm2 = NaN;
    tables = struct('name', {}, 'headers', {}, 'units', {}, 'data', {}, 'numericMask', {});
    logmsg = {};

    nLines = numel(lines);
    logmsg{end+1} = sprintf('Parsing DTA: %s', filepath);

    for i = 1:nLines
        tok = splitTabs(lines{i});
        if numel(tok) < 3
            continue;
        end

        key = upper(strtrim(tok{1}));
        val = tok{3};
        valNum = str2double(val);

        switch key
            case 'TAG'
                meta.tag = val;
            case 'TITLE'
                meta.title = val;
            case 'AREA'
                if isfinite(valNum)
                    meta.area_cm2 = valNum;
                end
        end
    end

    i = 1;
    while i <= nLines
        tok = splitTabs(lines{i});
        if numel(tok) >= 2 && strcmpi(tok{2}, 'TABLE')
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
                if numel(tokj) >= 2 && strcmpi(tokj{2}, 'TABLE')
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

function [curve, ok, msg] = getZCurve(tables)
    curve = struct();
    ok = false;
    msg = 'ZCURVE table not found.';

    if isempty(tables)
        return;
    end

    idx = [];
    for i = 1:numel(tables)
        if strcmpi(strtrim(tables(i).name), 'ZCURVE')
            idx = i;
            break;
        end
    end

    if isempty(idx)
        for i = 1:numel(tables)
            h = lower(string(tables(i).headers));
            if any(h == "freq") && any(h == "zreal") && any(h == "zimag")
                idx = i;
                break;
            end
        end
    end

    if isempty(idx)
        return;
    end

    curve = tables(idx);
    ok = true;
    msg = sprintf('Using table: %s', curve.name);
end

function col = defaultColumn(tbl, name)
    col = getColByName(tbl, name);
    if isempty(col)
        col = NaN(size(tbl.data, 1), 1);
    end
    col = col(:);
end

function col = getColByName(tbl, name)
    idx = find(strcmpi(tbl.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = tbl.data(:, idx);
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

function txt = labelForAxis(axisName)
    txt = axisName;
end

function tf = isNyquistSelection(xName, yName)
    tf = strcmp(xName, 'Zreal (ohm)') && ...
        (strcmp(yName, '-Zimag (ohm)') || strcmp(yName, 'Zimag (ohm)'));
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

function padded = padWithNaN(v, n)
    padded = NaN(n, 1);
    if isempty(v)
        return;
    end
    padded(1:numel(v)) = v(:);
end

function tf = isMostlyDescending(x)
    x = x(isfinite(x));
    if numel(x) < 2
        tf = false;
        return;
    end
    dx = diff(x);
    tf = sum(dx < 0) >= sum(dx > 0);
end

function out = sanitizeAxisName(txt)
    out = regexprep(lower(txt), '[^a-z0-9]+', '_');
    out = regexprep(out, '^_+|_+$', '');
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end

function txt = pluralS(n)
    if n == 1
        txt = '';
    else
        txt = 's';
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
