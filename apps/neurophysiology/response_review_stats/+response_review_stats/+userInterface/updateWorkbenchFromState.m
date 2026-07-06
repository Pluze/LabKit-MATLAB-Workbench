% App-owned renderer for Response Review Stats. Expected caller is
% labkit.ui.runtime.run after actions update state. Inputs are app state and UI
% registry. Side effects are limited to UI control, table, and axes updates.
function updateWorkbenchFromState(state, ui, ~)
    labkit.ui.control.setValue(ui, "inputFile", fileValue(state.inputFile));
    labkit.ui.control.setValue(ui, "baselineWindowSec", state.baselineWindowSec);
    labkit.ui.control.setValue(ui, "noiseWindowSec", state.noiseWindowSec);
    labkit.ui.control.setValue(ui, "outputFolder", ...
        char(outputFolderText(state.outputFolder)));
    labkit.ui.control.setEnabled(ui, "loadMetrics", ...
        strlength(state.inputFile) > 0);
    labkit.ui.control.setEnabled(ui, "exportMetrics", ...
        istable(state.metrics) && height(state.metrics) > 0 && ...
        strlength(state.outputFolder) > 0);
    labkit.ui.control.setValue(ui, "statusField", char(state.statusMessage));
    ui.controls.summaryTable.table.Data = ...
        response_review_stats.userInterface.summaryTableData(state);
    ui.controls.details.textArea.Value = ...
        response_review_stats.userInterface.detailLines(state);
    response_review_stats.userInterface.drawStatsPreview( ...
        ui.controls.preview.primaryAxes, state);
end

function items = fileValue(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        items = strings(0, 1);
        return;
    end
    items = pathValue;
end

function text = outputFolderText(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        text = "No output folder selected";
        return;
    end
    text = pathValue;
end
