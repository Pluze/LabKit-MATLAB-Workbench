% App-owned implementation for chrono_overlay.resultFiles.exportSelectedCurves within the chrono_overlay product workflow.
function state = exportSelectedCurves(state, context)
%EXPORTSELECTEDCURVES Let the user write the selected curves and manifest.
%
% Expected caller: the export button declared by Chrono Overlay. This
% framework-boundary callback reads the current selected indices, delegates
% table construction to buildOverlayExportTable, writes the chosen CSV and
% result package, and records the destinations in project results.

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
[folder, base, extension] = fileparts(outputPath);
outputName = string(base) + string(extension);
output = labkit.app.result.File( ...
    "overlayCurves", "primary", outputName, MediaType="text/csv");
result = labkit.app.result.Package( ...
    Outputs={output}, ...
    Inputs=struct("sources", state.project.inputs.sources), ...
    Parameters=state.project.parameters, ...
    Summary=struct("fileCount", numel(items)));
written = context.writeResultPackage(folder, result);
state.project.results.lastExport = struct( ...
    "csvPath", outputPath, "manifestPath", string(written.Value));
context.log("info", ...
    "chrono_overlay.resultfiles.exportselectedcurves.status", ...
    "Exported selected curve data.");
end

function items = selectedItems(items, indices)
indices = indices(indices <= numel(items));
items = items(indices);
end
