% App-owned runner extracted from labkit_EIS_app.m. Expected caller: labkit_EIS_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUNEISAPP Build and run the app body.

    S = struct();
    S.session = labkit.dta.makeSession('eis_overlay');
    S.items = S.session.items;

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
        "openFolder", @onOpenFolder, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportCSV", @onExportCSV, ...
        "selectionChanged", @(~,~) refreshPlot(), ...
        "plotOptionsChanged", @(~,~) refreshPlot());
    spec = eis.ui.buildSpec(axisItems, callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;
    lbFiles = ui.controls.files.listbox;
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
        if isempty(event.paths)
            addLog('Open cancelled.');
            return;
        end
        loadFiles(event.paths);
    end

    function onOpenFolder(~, ~)
        folder = uigetdir(labkit.ui.app.defaultDialogFolder("input"), ...
            'Select a folder to recursively scan for .DTA files');
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
        callbacks.onAdded = @onAddedDTA;
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));
        [S.session, report] = labkit.dta.addFilesToSession(S.session, filepaths, "eis", callbacks);
        S.items = S.session.items;

        refreshFileList();
        refreshPlot();

        if ~isempty(report.failed)
            firstError = report.failed(1);
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

    function onRemoveSelected(~, ~)
        if isempty(S.items) || isempty(lbFiles.Value)
            return;
        end
        callbacks = struct();
        callbacks.onRemoved = @(name, ~) addLog(sprintf('Removed: %s', name));
        [S.session, ~] = labkit.dta.removeSelectedItemsFromSession(S.session, lbFiles.Value, callbacks);
        S.items = S.session.items;
        refreshFileList();
        refreshPlot();
    end

    function onClearAll(~, ~)
        S.session = labkit.dta.makeSession('eis_overlay');
        S.items = S.session.items;
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
        labkit.ui.view.setListItems(ui, 'files', {S.items.name});
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

        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
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
        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_eis_plot_export.csv', 'Save current X/Y plot CSV', ...
            fullfile(labkit.ui.app.defaultDialogFolder("output"), ...
            'gamry_eis_plot_export.csv'));
        if isequal(f, 0)
            return;
        end

        T = eis.export.buildExportTable(items, ddX.Value, ddY.Value, cbLogX.Value, cbLogY.Value);
        out = fullfile(p, f);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', out));
    end

    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
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
