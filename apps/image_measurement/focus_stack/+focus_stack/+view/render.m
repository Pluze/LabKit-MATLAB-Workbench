% App-owned renderer for Focus Stack. Expected caller is labkit.ui.app.run
% after actions update state. Inputs are app state and UI registry. Side
% effects are limited to UI controls, preview axes, summary table, and close
% guard updates.
function render(state, ui, services)
    renderSourcePanel(state, ui);
    renderPreview(state, ui);
    renderSummary(state, ui);
    updateControls(state, ui);
    updateCloseGuard(state, ui, services.figure);
end

function renderSourcePanel(state, ui)
    labkit.ui.view.setValue(ui, 'sourceLocation', ...
        char(string(state.sourceLocation)));
    if isempty(state.images)
        labkit.ui.view.setValue(ui, 'sourceImages', {});
        return;
    end

    labkit.ui.view.setValue(ui, 'sourceImages', cellstr(state.paths));
end

function renderPreview(state, ui)
    if state.result.ok
        labkit.ui.view.drawImage(ui, 'preview', state.result.fused, ...
            'axis', 'fused', 'title', 'Fused all-in-focus image');
        labkit.ui.view.drawImage(ui, 'preview', ...
            focus_stack.view.focusIndexRgb(state.result.focusIndex, ...
            state.result.inputCount), ...
            'axis', 'focusMap', 'title', 'Focus-depth index map');
    elseif ~isempty(state.images)
        labkit.ui.view.drawImage(ui, 'preview', ...
            focus_stack.view.previewImage(state.images{1}), ...
            'axis', 'fused', 'title', 'First source image');
        resetFocusMapAxis(ui);
    else
        resetPreviewAxes(ui);
    end
end

function renderSummary(state, ui)
    if state.result.ok
        ui.controls.resultTable.table.Data = ...
            focus_stack.view.resultTableData(state.result);
        labkit.ui.view.setValue(ui, 'details', ...
            focus_stack.view.details(state.result, state.paths, ...
            state.registrationLines));
    elseif numel(state.images) >= 2
        ui.controls.resultTable.table.Data = focus_stack.view.initialResultTable();
        labkit.ui.view.setValue(ui, 'details', { ...
            sprintf('Loaded images: %d', numel(state.images)), ...
            'Run focus stack to compute the fused image and focus-depth map.'});
    elseif ~isempty(state.images)
        ui.controls.resultTable.table.Data = focus_stack.view.initialResultTable();
        labkit.ui.view.setValue(ui, 'details', { ...
            sprintf('Loaded images: %d', numel(state.images)), ...
            'Load at least two images before running focus stack.'});
    else
        ui.controls.resultTable.table.Data = focus_stack.view.initialResultTable();
        labkit.ui.view.setValue(ui, 'details', ...
            {'Load a focus image folder or select image files to begin.'});
    end
end

function updateControls(state, ui)
    hasImages = ~isempty(state.images);
    hasStack = numel(state.images) >= 2;
    hasResult = state.result.ok;
    ui.controls.sourceImages.clearButton.Enable = onOff(hasImages);
    ui.controls.sourceImages.listbox.Enable = onOff(hasImages);
    labkit.ui.view.setEnabled(ui, 'runFocusStack', hasStack);
    labkit.ui.view.setEnabled(ui, 'exportFused', hasResult);
    labkit.ui.view.setEnabled(ui, 'exportFocusMap', hasResult);
    labkit.ui.view.setEnabled(ui, 'exportSummary', hasResult);
end

function updateCloseGuard(state, ui, fig)
    dirty = false;
    if numel(state.images) >= 2
        task = focus_stack.state.runTask(state.paths, state.images, ...
            currentFusionOptions(ui), labkit.ui.view.getValue(ui, ...
            'autoRegister'));
        dirty = ~state.result.ok || state.lastRunFingerprint ~= task.fingerprint;
    end
    labkit.ui.app.setCloseGuard(fig, dirty, ...
        "Focus stack has unrun changes. Close anyway?");
end

function resetPreviewAxes(ui)
    labkit.ui.view.resetAxes(ui, 'preview', 'Fused all-in-focus image', ...
        true, 'fused');
    resetFocusMapAxis(ui);
end

function resetFocusMapAxis(ui)
    labkit.ui.view.resetAxes(ui, 'preview', 'Focus-depth index map', ...
        true, 'focusMap');
end

function opts = currentFusionOptions(ui)
    opts = struct();
    opts.focusWindow = finiteScalar(labkit.ui.view.getValue(ui, ...
        'focusWindow'), 7, 3, inf, true);
    opts.smoothRadius = finiteScalar(labkit.ui.view.getValue(ui, ...
        'smoothRadius'), 1, 0, inf, true);
    opts.minConfidence = finiteScalar(labkit.ui.view.getValue(ui, ...
        'uncertainBlend'), 25, 0, 100, false) / 100;
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

function value = finiteScalar(value, fallback, minValue, maxValue, roundValue)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
    value = min(max(value, minValue), maxValue);
    if roundValue
        value = round(value);
    end
end
