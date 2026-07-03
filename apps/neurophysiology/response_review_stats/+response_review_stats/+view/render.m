% App-owned renderer for Response Review Stats. Expected caller is
% labkit.ui.app.run after actions update state. Inputs are app state and UI
% registry. Side effects are limited to UI control, table, and axes updates.
function render(state, ui, ~)
    labkit.ui.view.setValue(ui, "inputFile", fileValue(state.inputFile));
    labkit.ui.view.setValue(ui, "baselineWindowSec", state.baselineWindowSec);
    labkit.ui.view.setValue(ui, "noiseWindowSec", state.noiseWindowSec);
    labkit.ui.view.setValue(ui, "outputFolder", ...
        char(outputFolderText(state.outputFolder)));
    labkit.ui.view.setEnabled(ui, "loadMetrics", ...
        strlength(state.inputFile) > 0);
    labkit.ui.view.setEnabled(ui, "exportMetrics", ...
        istable(state.metrics) && height(state.metrics) > 0 && ...
        strlength(state.outputFolder) > 0);
    labkit.ui.view.setValue(ui, "statusField", char(state.statusMessage));
    ui.controls.summaryTable.table.Data = ...
        response_review_stats.view.summaryTableData(state);
    ui.controls.details.textArea.Value = ...
        response_review_stats.view.detailLines(state);
    response_review_stats.view.drawStatsPreview( ...
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
