% App-owned runner extracted from labkit_ChronoOverlay_app.m. Expected caller: labkit_ChronoOverlay_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUNCHRONOOVERLAYAPP Build and run the app body.

    S = struct();
    S.items = struct([]);

    callbacks = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportCSV", @onExportCSV, ...
        "selectionChanged", @(~,~) refreshPlots(), ...
        "plotOptionsChanged", @(~,~) refreshPlots());
    spec = chrono_overlay.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;
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

            [item, status] = labkit.dta.loadFile(filepath, "chrono");
            if ~status.ok
                failed(end + 1) = struct( ...
                    'filepath', char(filepath), ...
                    'message', char(status.message));
                addLog(sprintf('Failed: %s | %s', char(filepath), char(status.message)));
                continue;
            end

            [item, alignMsg] = chrono_overlay.ops.alignByPulseGap(item);
            S.items = appendItem(S.items, item);
            addLog(alignMsg);
            for ii = 1:numel(item.logmsg)
                addLog(item.logmsg{ii});
            end
            addLog(sprintf('%s: %s', item.name, item.message));
            addLog(sprintf('Loaded: %s', char(filepath)));
        end

        refreshFileList();
        refreshPlots();

        if ~isempty(failed)
            firstError = failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
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
            labkit.ui.view.setListItems(ui, 'files', {});
            txtLoaded.Value = 'No files loaded';
            return;
        end
        labkit.ui.view.setValue(ui, 'files', string({S.items.filepath}).');
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshPlots()
        if isempty(S.items)
            chrono_overlay.view.plotVTIT(axV, axI, struct([]), plotOptions());
            return;
        end

        items = selectedItems();
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

        items = selectedItems();
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [out, cancelled] = labkit.ui.app.promptOutputFile( ...
            'gamry_overlay_curves.csv', 'Save overlay curves CSV', ...
            'gamry_overlay_curves.csv');
        if cancelled
            return;
        end

        T = chrono_overlay.export.buildOverlayExportTable(items);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', char(out)));
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
