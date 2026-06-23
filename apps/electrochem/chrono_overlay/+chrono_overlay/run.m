% App-owned runner extracted from labkit_ChronoOverlay_app.m. Expected caller: labkit_ChronoOverlay_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUNCHRONOOVERLAYAPP Build and run the app body.

    S = struct();
    S.session = labkit.dta.makeSession('chrono_overlay');
    S.items = S.session.items;

    callbacks = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "openFolder", @onOpenFolder, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportCSV", @onExportCSV, ...
        "selectionChanged", @(~,~) refreshPlots(), ...
        "plotOptionsChanged", @(~,~) refreshPlots());
    spec = chrono_overlay.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;
    lbFiles = ui.controls.files.listbox;
    txtLoaded = ui.controls.files.status;
    ddXAxis = ui.controls.xAxis.valueHandle;
    edLineWidth = ui.controls.lineWidth.valueHandle;
    cbLegend = ui.controls.showLegend.valueHandle;
    cbGrid = ui.controls.showGrid.valueHandle;
    axV = ui.controls.overlayPlots.axesById.voltage;
    axI = ui.controls.overlayPlots.axesById.current;
    if debugLog.enabled
        debugLog.trace('Chrono overlay debug trace enabled.');
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
            [item, alignMsg] = chrono_overlay.ops.alignByPulseGap(item);
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
            labkit.ui.view.setListItems(ui, 'files', {});
            txtLoaded.Value = 'No files loaded';
            return;
        end
        labkit.ui.view.setListItems(ui, 'files', {S.items.name});
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshPlots()
        if isempty(S.items)
            chrono_overlay.view.plotVTIT(axV, axI, struct([]), plotOptions());
            return;
        end

        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            cla(axV);
            cla(axI);
            return;
        end

        chrono_overlay.view.plotVTIT(axV, axI, items, plotOptions());
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

        [f, p] = uiputfile('gamry_overlay_curves.csv', 'Save overlay curves CSV', ...
            fullfile(labkit.ui.app.defaultDialogFolder("output"), 'gamry_overlay_curves.csv'));
        if isequal(f, 0)
            return;
        end

        T = chrono_overlay.export.buildOverlayExportTable(items);
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
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end
end
