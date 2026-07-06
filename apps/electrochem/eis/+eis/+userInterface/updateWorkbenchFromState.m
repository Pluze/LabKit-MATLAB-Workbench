% App-owned renderer for EIS Overlay. Expected caller is labkit.ui.runtime.run
% after actions update state. Inputs are app state, UI registry, and runtime
% services. Side effects are limited to UI control and axes updates.
function updateWorkbenchFromState(state, ui, ~)
    renderFileList(state, ui);
    renderPlot(state, ui);
end

function renderFileList(state, ui)
    if isempty(state.items)
        labkit.ui.control.setListItems(ui, 'files', {});
        ui.controls.files.status.Value = 'No files loaded';
        return;
    end
    labkit.ui.control.setValue(ui, 'files', string({state.items.filepath}).');
    ui.controls.files.status.Value = sprintf('%d file(s) loaded', ...
        numel(state.items));
end

function renderPlot(state, ui)
    ax = ui.controls.plot.axesById.overlay;
    opts = plotOptions(ui);
    labkit.ui.plot.clear(ax, "ResetScale", true);
    ax.XScale = ternary(opts.logX, 'log', 'linear');
    ax.YScale = ternary(opts.logY, 'log', 'linear');
    axis(ax, 'normal');

    if isempty(state.items)
        title(ax, 'EIS Overlay');
        xlabel(ax, eis.userInterface.labelForAxis(opts.xName));
        ylabel(ax, eis.userInterface.labelForAxis(opts.yName));
        ui.controls.summary.textArea.Value = {'No files loaded.'};
        return;
    end

    items = selectedItems(state, ui);
    if isempty(items)
        title(ax, 'EIS Overlay');
        xlabel(ax, eis.userInterface.labelForAxis(opts.xName));
        ylabel(ax, eis.userInterface.labelForAxis(opts.yName));
        ui.controls.summary.textArea.Value = {'No files selected.'};
        return;
    end

    eis.userInterface.plotOverlay(ax, items, opts);
    ui.controls.summary.textArea.Value = eis.userInterface.buildSummary(items);
end

function items = selectedItems(state, ui)
    files = labkit.ui.control.getValue(ui, 'files');
    paths = labkit.ui.control.filePaths(files);
    if isempty(paths)
        items = struct([]);
        return;
    end
    keep = ismember(string({state.items.filepath}), string(paths(:)));
    items = state.items(keep);
end

function opts = plotOptions(ui)
    opts = struct();
    opts.xName = ui.controls.xAxis.valueHandle.Value;
    opts.yName = ui.controls.yAxis.valueHandle.Value;
    opts.logX = ui.controls.logX.valueHandle.Value;
    opts.logY = ui.controls.logY.valueHandle.Value;
    opts.lineWidth = ui.controls.lineWidth.valueHandle.Value;
    opts.markerSize = ui.controls.markerSize.valueHandle.Value;
    opts.showMarkers = ui.controls.showMarkers.valueHandle.Value;
    opts.showLegend = ui.controls.showLegend.valueHandle.Value;
    opts.showGrid = ui.controls.showGrid.valueHandle.Value;
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end
