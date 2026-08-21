% App-owned implementation for chrono_overlay.resultFiles.exportSelectedCurves within the chrono_overlay product workflow.
function state = exportSelectedCurves(state, context)
%EXPORTSELECTEDCURVES Let the user write the selected curves.
%
% Expected caller: the export button declared by Chrono Overlay. This
% framework-boundary callback reads the current selected indices, delegates
% table construction to buildOverlayExportTable and records the chosen CSV.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

items = selectedItems(state.session.cache.items, ...
    state.session.selection.files.Indices);
if isempty(items)
    context.alert("No files selected for export.", "Export");
    return;
end
chosen = context.chooseOutputFile( ...
    ["*.csv", "CSV files (*.csv)"], pwd);
if chosen.Cancelled
    return;
end
outputPath = string(chosen.Value);
tableValue = chrono_overlay.resultFiles.buildOverlayExportTable(items);
writetable(tableValue, outputPath);
state.project.results.lastExport = struct( ...
    "csvPath", outputPath, "outputPath", outputPath);
context.log("info", ...
    "chrono_overlay.resultfiles.exportselectedcurves.status", ...
    "Exported selected curve data.");
end

function items = selectedItems(items, indices)
indices = indices(indices <= numel(items));
items = items(indices);
end
