% App-owned renderer for DIC Postprocess. Expected caller is labkit.ui.app.run
% after actions update state. Inputs are app state and UI registry. Side
% effects are limited to UI control, table, text, and axes updates.
function updateWorkbenchFromState(state, ui, ~)
    labkit.ui.view.setValue(ui, "matFile", fileValue(state.matPath));
    labkit.ui.view.setValue(ui, "referenceFile", fileValue(state.referencePath));
    labkit.ui.view.setValue(ui, "maskFile", fileValue(state.maskPath));
    ui.controls.resultTable.table.Data = ...
        dic_postprocess.userInterface.summaryTableData(state.summaryTable);
    ui.controls.summaryText.textArea.Value = summaryLines(state, ui);
    renderOverlays(state, ui);
end

function renderOverlays(state, ui)
    if isempty(state.overlayExx) || isempty(state.overlayEyy)
        labkit.ui.view.resetAxes(ui, 'overlayAxes', ...
            'EXX Overlay', true, 'exx');
        labkit.ui.view.resetAxes(ui, 'overlayAxes', ...
            'EYY Overlay', true, 'eyy');
        return;
    end
    dic_postprocess.userInterface.showImage(ui, state.overlayExx, 'EXX Overlay', 'exx');
    dic_postprocess.userInterface.showImage(ui, state.overlayEyy, 'EYY Overlay', 'eyy');
end

function lines = summaryLines(state, ui)
    lines = {};
    lines{end + 1} = sprintf('DIC MAT: %s', ...
        dic_postprocess.userInterface.displayPath(state.matPath));
    lines{end + 1} = sprintf('Reference image: %s', ...
        dic_postprocess.userInterface.displayPath(state.referencePath));
    lines{end + 1} = sprintf('Mask image: %s', ...
        dic_postprocess.userInterface.displayPath(state.maskPath));
    lines{end + 1} = sprintf('Overlays: %s', ...
        dic_postprocess.userInterface.ternary(~isempty(state.overlayExx), ...
        'available', 'not generated'));
    lines{end + 1} = sprintf(['Optical image: brightness %.3g, ' ...
        'contrast %.3g, gamma %.3g, saturation %.3g'], ...
        ui.controls.brightness.valueHandle.Value, ...
        ui.controls.contrast.valueHandle.Value, ...
        ui.controls.gamma.valueHandle.Value, ...
        ui.controls.saturation.valueHandle.Value);
end

function items = fileValue(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        items = strings(0, 1);
        return;
    end
    items = pathValue;
end
