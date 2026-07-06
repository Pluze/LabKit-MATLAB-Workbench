% App-owned renderer for Chrono Overlay. Expected caller is labkit.ui.runtime.run
% after actions update state. Inputs are app state, UI registry, and runtime
% services. Side effects are limited to UI control and axes updates.
function updateWorkbenchFromState(state, ui, ~)
    renderFileList(state, ui);
    renderPlots(state, ui);
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

function renderPlots(state, ui)
    axV = ui.controls.overlayPlots.axesById.voltage;
    axI = ui.controls.overlayPlots.axesById.current;
    if isempty(state.items)
        chrono_overlay.userInterface.plotVTIT(axV, axI, struct([]), plotOptions(ui));
        return;
    end

    items = selectedItems(state, ui);
    if isempty(items)
        chrono_overlay.userInterface.plotVTIT(axV, axI, struct([]), plotOptions(ui));
        return;
    end

    chrono_overlay.userInterface.plotVTIT(axV, axI, items, plotOptions(ui));
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
    opts.xAxis = ui.controls.xAxis.valueHandle.Value;
    opts.lineWidth = ui.controls.lineWidth.valueHandle.Value;
    opts.showGrid = ui.controls.showGrid.valueHandle.Value;
    opts.showLegend = ui.controls.showLegend.valueHandle.Value;
end
