% App-owned renderer for Chrono Overlay. Expected caller is labkit.ui.app.run
% after actions update state. Inputs are app state, UI registry, and runtime
% services. Side effects are limited to UI control and axes updates.
function render(state, ui, ~)
    renderFileList(state, ui);
    renderPlots(state, ui);
end

function renderFileList(state, ui)
    if isempty(state.items)
        labkit.ui.view.setListItems(ui, 'files', {});
        ui.controls.files.status.Value = 'No files loaded';
        return;
    end
    labkit.ui.view.setValue(ui, 'files', string({state.items.filepath}).');
    ui.controls.files.status.Value = sprintf('%d file(s) loaded', ...
        numel(state.items));
end

function renderPlots(state, ui)
    axV = ui.controls.overlayPlots.axesById.voltage;
    axI = ui.controls.overlayPlots.axesById.current;
    if isempty(state.items)
        chrono_overlay.view.plotVTIT(axV, axI, struct([]), plotOptions(ui));
        return;
    end

    items = selectedItems(state, ui);
    if isempty(items)
        cla(axV);
        cla(axI);
        return;
    end

    chrono_overlay.view.plotVTIT(axV, axI, items, plotOptions(ui));
end

function items = selectedItems(state, ui)
    files = labkit.ui.view.getValue(ui, 'files');
    paths = labkit.ui.view.filePaths(files);
    if isempty(paths)
        items = struct([]);
        return;
    end
    keep = ismember(string({state.items.filepath}), string(paths(:)));
    items = state.items(keep);
end

function opts = plotOptions(ui)
    opts = struct();
    opts.xAxis = ui.controls.xAxis.valueHandle.Value;
    opts.lineWidth = ui.controls.lineWidth.valueHandle.Value;
    opts.showGrid = ui.controls.showGrid.valueHandle.Value;
    opts.showLegend = ui.controls.showLegend.valueHandle.Value;
end
