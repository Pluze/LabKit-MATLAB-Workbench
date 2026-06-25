% App-owned runner extracted from labkit_EIS_app.m. Expected caller: labkit_EIS_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUNEISAPP Build and run the app body.

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

    callbacks = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportCSV", @onExportCSV, ...
        "selectionChanged", @(~,~) refreshPlot(), ...
        "plotOptionsChanged", @(~,~) refreshPlot());
    spec = eis.ui.buildSpec(axisItems, callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;
    txtLoaded = ui.controls.files.status;
    ddX = ui.controls.xAxis.valueHandle;
    ddY = ui.controls.yAxis.valueHandle;
    edLineWidth = ui.controls.lineWidth.valueHandle;
    edMarkerSize = ui.controls.markerSize.valueHandle;
    cbMarkers = ui.controls.showMarkers.valueHandle;
    cbLogX = ui.controls.logX.valueHandle;
    cbLogY = ui.controls.logY.valueHandle;
    cbLegend = ui.controls.showLegend.valueHandle;
    cbGrid = ui.controls.showGrid.valueHandle;
    ax = ui.controls.plot.axesById.overlay;
    txtSummary = ui.controls.summary.textArea;
    txtSummary.Value = {'No files loaded.'};
    if debugLog.enabled
        debugLog.trace('EIS debug trace enabled.');
    end
    %% App callbacks, session actions, refresh, and export
    function onOpenFilesChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Open cancelled.');
            return;
        end
        loadFiles(paths);
    end

    function loadFiles(filepaths)
        filepaths = normalizePaths(filepaths);
        if isempty(filepaths)
            return;
        end

        failed = struct('filepath', {}, 'message', {});
        for iFile = 1:numel(filepaths)
            filepath = filepaths(iFile);
            if isLoaded(filepath)
                addLog(sprintf('Skipped already loaded: %s', char(filepath)));
                continue;
            end

            [item, status] = labkit.dta.loadFile(filepath, "eis");
            if ~status.ok
                failed(end + 1) = struct( ...
                    'filepath', char(filepath), ...
                    'message', char(status.message));
                addLog(sprintf('Failed: %s | %s', char(filepath), char(status.message)));
                continue;
            end

            S.items = appendItem(S.items, item);
            onAddedDTA(char(filepath), item);
        end

        refreshFileList();
        refreshPlot();

        if ~isempty(failed)
            firstError = failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function onAddedDTA(filepath, item)
        for ii = 1:numel(item.logmsg)
            addLog(item.logmsg{ii});
        end
        addLog(sprintf('%s: %s', item.name, item.message));
        addLog(sprintf('Loaded: %s', filepath));
    end

    function onRemoveSelected(~, event)
        if isempty(S.items)
            return;
        end
        paths = labkit.ui.view.filePaths(event.removedFiles);
        if isempty(paths)
            return;
        end
        report = removeItemsByPaths(paths);
        for k = 1:numel(report.removed)
            addLog(sprintf('Removed: %s', report.removed{k}));
        end
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
            labkit.ui.view.setListItems(ui, 'files', {});
            txtLoaded.Value = 'No files loaded';
            return;
        end
        labkit.ui.view.setValue(ui, 'files', string({S.items.filepath}).');
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshPlot()
        cla(ax);
        ax.XScale = ternary(cbLogX.Value, 'log', 'linear');
        ax.YScale = ternary(cbLogY.Value, 'log', 'linear');
        axis(ax, 'normal');

        if isempty(S.items)
            title(ax, 'EIS Overlay');
            xlabel(ax, eis.view.labelForAxis(ddX.Value));
            ylabel(ax, eis.view.labelForAxis(ddY.Value));
            txtSummary.Value = {'No files loaded.'};
            return;
        end

        items = selectedItems();
        if isempty(items)
            txtSummary.Value = {'No files selected.'};
            return;
        end

        plotOpts = struct();
        plotOpts.xName = ddX.Value;
        plotOpts.yName = ddY.Value;
        plotOpts.logX = cbLogX.Value;
        plotOpts.logY = cbLogY.Value;
        plotOpts.lineWidth = edLineWidth.Value;
        plotOpts.markerSize = edMarkerSize.Value;
        plotOpts.showMarkers = cbMarkers.Value;
        plotOpts.showLegend = cbLegend.Value;
        plotOpts.showGrid = cbGrid.Value;
        eis.view.plotOverlay(ax, items, plotOpts);

        txtSummary.Value = eis.view.buildSummary(items);
    end

    function onExportCSV(~, ~)
        items = selectedItems();
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [out, cancelled] = labkit.ui.app.promptOutputFile( ...
            'gamry_eis_plot_export.csv', 'Save current X/Y plot CSV', ...
            'gamry_eis_plot_export.csv');
        if cancelled
            return;
        end

        T = eis.export.buildExportTable(items, ddX.Value, ddY.Value, cbLogX.Value, cbLogY.Value);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', char(out)));
    end

    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end

    function items = selectedItems()
        files = labkit.ui.view.getValue(ui, 'files');
        paths = labkit.ui.view.filePaths(files);
        if isempty(paths)
            items = struct([]);
            return;
        end
        keep = ismember(string({S.items.filepath}), string(paths(:)));
        items = S.items(keep);
    end

    function report = removeItemsByPaths(filepaths)
        paths = normalizePaths(filepaths);
        report = struct('removed', {{}}, 'missing', {{}});
        if isempty(paths)
            return;
        end
        if isempty(S.items)
            report.missing = cellstr(paths(:).');
            return;
        end
        keep = true(1, numel(S.items));
        itemPaths = string({S.items.filepath});
        for k = 1:numel(paths)
            idx = find(itemPaths == paths(k) & keep, 1, 'first');
            if isempty(idx)
                report.missing{end + 1} = char(paths(k));
                continue;
            end
            report.removed{end + 1} = char(paths(k));
            keep(idx) = false;
        end
        S.items = S.items(keep);
    end

    function tf = isLoaded(filepath)
        tf = ~isempty(S.items) && any(string({S.items.filepath}) == string(filepath));
    end

    function paths = normalizePaths(paths)
        paths = string(paths(:));
        paths = paths(strlength(paths) > 0);
    end

    function items = appendItem(items, item)
        if isempty(items)
            items = item;
        else
            items(end + 1) = item;
        end
    end
end

%% Small app-local utilities
function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end
