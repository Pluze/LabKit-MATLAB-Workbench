% App-owned renderer for CIC. Expected caller is labkit.ui.runtime.run after
% actions update state. Inputs are app state and UI registry. Side effects
% are limited to UI control, table, text, and axes updates.
function updateWorkbenchFromState(state, ui, ~)
    renderFileList(state, ui);
    renderBatchTable(state, ui);
    renderResultsSummary(state, ui);
    renderPlots(state, ui);
end

function renderFileList(state, ui)
    if isempty(state.items)
        labkit.ui.control.setListItems(ui, 'files', {});
        ui.controls.files.status.Value = 'No files loaded';
        return;
    end

    paths = string({state.items.filepath}).';
    labkit.ui.control.setValue(ui, 'files', paths);
    current = currentIndex(state);
    files = labkit.ui.control.getFiles(ui, 'files');
    labkit.ui.control.setFileSelection(ui, 'files', files(current));
    ui.controls.files.status.Value = sprintf('%d file(s) loaded', ...
        numel(state.items));
end

function renderBatchTable(state, ui)
    [~, unitLabel] = cic.userInterface.displayUnit(ui.controls.cicUnit.valueHandle.Value);
    [data, columnNames] = cic.userInterface.buildBatchTableData(state.items, unitLabel);
    ui.controls.results.table.ColumnName = columnNames;
    if isempty(state.items)
        ui.controls.results.table.Data = cell(0, 8);
    else
        ui.controls.results.table.Data = data;
    end
end

function renderResultsSummary(state, ui)
    summary = cic.userInterface.buildCurrentSummary(state.items, state.current, ...
        ui.controls.cicMode.valueHandle.Value, ...
        ui.controls.cicUnit.valueHandle.Value);
    ui.controls.controlMode.valueHandle.Value = summary.controlMode;
    ui.controls.detect.valueHandle.Value = summary.detect;
    ui.controls.delay.valueHandle.Value = summary.delay;
    ui.controls.areaSummary.valueHandle.Value = summary.area;
    ui.controls.emc.valueHandle.Value = summary.emc;
    ui.controls.ema.valueHandle.Value = summary.ema;
    ui.controls.qc.valueHandle.Value = summary.qc;
    ui.controls.qa.valueHandle.Value = summary.qa;
    ui.controls.qt.valueHandle.Value = summary.qt;
    ui.controls.safe.valueHandle.Value = summary.safe;
    ui.controls.best.valueHandle.Value = summary.bestSafe;
end

function renderPlots(state, ui)
    axTop = ui.controls.plotAxes.axesById.top;
    axBottom = ui.controls.plotAxes.axesById.bottom;
    clearAxis(axTop);
    clearAxis(axBottom);
    if isempty(state.items) || isempty(state.current) || ...
            state.current < 1 || state.current > numel(state.items)
        title(axTop, 'Top Plot');
        title(axBottom, 'Bottom Plot');
        return;
    end

    item = state.items(state.current);
    if isempty(item.analysis) || ~item.analysis.ok
        title(axTop, 'Top Plot');
        title(axBottom, 'Bottom Plot');
        text(axTop, 0.5, 0.5, 'No valid analysis', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
        return;
    end

    analysis = item.analysis;
    plotOneAxis(axTop, analysis, ui.controls.topX.valueHandle.Value, ...
        ui.controls.topY.valueHandle.Value, ...
        ui.controls.topGrid.valueHandle.Value, item.name, ui);
    plotOneAxis(axBottom, analysis, ui.controls.bottomX.valueHandle.Value, ...
        ui.controls.bottomY.valueHandle.Value, ...
        ui.controls.bottomGrid.valueHandle.Value, item.name, ui);
end

function plotOneAxis(ax, analysis, xChoice, yChoice, showGrid, itemName, ui)
    request = cic.userInterface.plotRequest(analysis, itemName, xChoice, yChoice);
    coords = request.coords;

    hLine = plot(ax, request.x, request.y, 'LineWidth', 1.25, ...
        'Color', request.baseColor);
    labkit.ui.plot.fit(ax, hLine);
    hold(ax, 'on');

    if ui.controls.showShading.valueHandle.Value
        cic.userInterface.shadeWindow(ax, coords.cathStartX, coords.cathEndX, ...
            [0.85 0.93 1.00]);
        cic.userInterface.shadeWindow(ax, coords.anodStartX, coords.anodEndX, ...
            [1.00 0.92 0.85]);
    end

    if strcmp(request.kind, 'VT') && ui.controls.showLimits.valueHandle.Value
        yline(ax, analysis.cathLimit, '--', ...
            sprintf('Cath limit = %.3f V', analysis.cathLimit), ...
            'Color', [0.85 0.2 0.2], 'LabelHorizontalAlignment', 'left');
        yline(ax, analysis.anodLimit, '--', ...
            sprintf('Anod limit = %.3f V', analysis.anodLimit), ...
            'Color', [0.85 0.2 0.2], 'LabelHorizontalAlignment', 'left');
    end

    if strcmp(request.kind, 'VT')
        cic.userInterface.addBaselineYLines(ax, analysis);
    end

    if ui.controls.showMarkers.valueHandle.Value
        xline(ax, coords.cathStartX, ':', 'Cath start', 'Color', [0.2 0.4 0.8]);
        xline(ax, coords.cathEndX, ':', 'Cath end', 'Color', [0.2 0.4 0.8]);
        xline(ax, coords.anodStartX, ':', 'Anod start', 'Color', [0.8 0.4 0.2]);
        xline(ax, coords.anodEndX, ':', 'Anod end', 'Color', [0.8 0.4 0.2]);
        if strcmp(request.kind, 'VT')
            cic.userInterface.addPaperStyleVTAnnotations(ax, analysis, xChoice, ...
                coords.cathStartX, coords.cathEndX, coords.anodStartX, ...
                coords.anodEndX, coords.emcX, coords.emaX);
        else
            cic.userInterface.addPaperStyleITAnnotations(ax, analysis, xChoice, ...
                coords.cathStartX, coords.cathEndX, coords.anodStartX, ...
                coords.anodEndX, coords.emcX, coords.emaX);
        end
    end
    hold(ax, 'off');

    title(ax, request.title, 'Interpreter', 'none');
    xlabel(ax, request.xLabel);
    ylabel(ax, request.yLabel);
    if showGrid
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end
end

function idx = currentIndex(state)
    idx = state.current;
    if isempty(idx) || idx < 1 || idx > numel(state.items)
        idx = 1;
    end
end

function clearAxis(ax)
    labkit.ui.plot.clear(ax, "ResetScale", true);
end
