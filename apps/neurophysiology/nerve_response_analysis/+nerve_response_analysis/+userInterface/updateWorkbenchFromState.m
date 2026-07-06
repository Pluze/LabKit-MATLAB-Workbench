% App-owned renderer for Nerve Response Analysis. Expected caller is
% labkit.ui.runtime.run after actions update state. Inputs are app state and UI
% registry. Side effects are limited to UI control, table, and axes updates.
function updateWorkbenchFromState(state, ui, ~)
    labkit.ui.control.setValue(ui, "sessionFile", fileValue(state.sessionFile));
    labkit.ui.control.setValue(ui, "protocolFile", fileValue(state.protocolFile));
    labkit.ui.control.setValue(ui, "maxRecordings", state.maxRecordings);
    labkit.ui.control.setValue(ui, "maxDurationSec", state.maxDurationSec);
    labkit.ui.control.setValue(ui, "outputFolder", ...
        char(outputFolderText(state.outputFolder)));
    labkit.ui.control.setEnabled(ui, "runAnalysis", ...
        strlength(state.sessionFile) > 0);
    labkit.ui.control.setEnabled(ui, "exportAnalysis", ...
        ~isempty(state.analysis) && strlength(state.outputFolder) > 0);
    labkit.ui.control.setValue(ui, "statusField", char(state.statusMessage));
    ui.controls.summaryTable.table.Data = ...
        nerve_response_analysis.userInterface.summaryTableData(state);
    ui.controls.details.textArea.Value = ...
        nerve_response_analysis.userInterface.detailLines(state);
    nerve_response_analysis.userInterface.drawAnalysisPreview( ...
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
