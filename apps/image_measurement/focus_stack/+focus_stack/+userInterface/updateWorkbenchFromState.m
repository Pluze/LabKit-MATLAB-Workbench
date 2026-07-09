% App-owned renderer for Focus Stack. Expected caller is labkit.ui.runtime.run
% after actions update state. Inputs are app state and UI registry. Side
% effects are limited to UI controls, preview axes, and summary table.
function updateWorkbenchFromState(state, ui, services)
    renderSourcePanel(state, ui);
    renderPreview(state, ui);
    renderSummary(state, ui);
    updateControls(state, ui);
end

function renderSourcePanel(state, ui)
    labkit.ui.control.setValue(ui, 'sourceLocation', ...
        char(string(state.sourceLocation)));
    if isempty(state.images)
        labkit.ui.control.setValue(ui, 'sourceImages', {});
        return;
    end

    labkit.ui.control.setValue(ui, 'sourceImages', cellstr(state.paths));
end

function renderPreview(state, ui)
    if state.result.ok
        labkit.ui.plot.image(ui, 'preview', state.result.fused, ...
            'axis', 'fused', 'title', 'Fused all-in-focus image');
        labkit.ui.plot.image(ui, 'preview', ...
            focus_stack.userInterface.focusIndexRgb(state.result.focusIndex, ...
            state.result.inputCount), ...
            'axis', 'focusMap', 'title', 'Focus-depth index map');
    elseif ~isempty(state.images)
        labkit.ui.plot.image(ui, 'preview', ...
            focus_stack.userInterface.previewImage(state.images{1}), ...
            'axis', 'fused', 'title', 'First source image');
        resetFocusMapAxis(ui);
    else
        resetPreviewAxes(ui);
    end
end

function renderSummary(state, ui)
    if state.result.ok
        ui.controls.resultTable.table.Data = ...
            focus_stack.userInterface.resultTableData(state.result);
        labkit.ui.control.setValue(ui, 'details', ...
            focus_stack.userInterface.details(state.result, state.paths, ...
            state.registrationLines));
    elseif numel(state.images) >= 2
        ui.controls.resultTable.table.Data = focus_stack.userInterface.initialResultTable();
        labkit.ui.control.setValue(ui, 'details', { ...
            sprintf('Loaded images: %d', numel(state.images)), ...
            'Run focus stack to compute the fused image and focus-depth map.'});
    elseif ~isempty(state.images)
        ui.controls.resultTable.table.Data = focus_stack.userInterface.initialResultTable();
        labkit.ui.control.setValue(ui, 'details', { ...
            sprintf('Loaded images: %d', numel(state.images)), ...
            'Load at least two images before running focus stack.'});
    else
        ui.controls.resultTable.table.Data = focus_stack.userInterface.initialResultTable();
        labkit.ui.control.setValue(ui, 'details', ...
            {'Load a focus image folder or select image files to begin.'});
    end
end

function updateControls(state, ui)
    hasImages = ~isempty(state.images);
    hasStack = numel(state.images) >= 2;
    hasResult = state.result.ok;
    ui.controls.sourceImages.clearButton.Enable = onOff(hasImages);
    ui.controls.sourceImages.listbox.Enable = onOff(hasImages);
    labkit.ui.control.setEnabled(ui, 'runFocusStack', hasStack);
    labkit.ui.control.setEnabled(ui, 'exportFused', hasResult);
    labkit.ui.control.setEnabled(ui, 'exportFocusMap', hasResult);
    labkit.ui.control.setEnabled(ui, 'exportSummary', hasResult);
end

function resetPreviewAxes(ui)
    labkit.ui.plot.reset(ui, 'preview', 'Fused all-in-focus image', ...
        true, 'fused');
    resetFocusMapAxis(ui);
end

function resetFocusMapAxis(ui)
    labkit.ui.plot.reset(ui, 'preview', 'Focus-depth index map', ...
        true, 'focusMap');
end

function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end
