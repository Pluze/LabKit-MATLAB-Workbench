% App-owned commands for Chrono Overlay. Standard bindings, file collection,
% project persistence, and resource cleanup remain runtime-owned.
function commands = definitionActions()
    commands = struct( ...
        "exportCSV", labkit.ui.Command("exportCSV", @onExportCSV));
end

function state = onExportCSV(state, context)
    items = selectedItems(state);
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
    output = labkit.ui.ResultOutput( ...
        "overlayCurves", "primary", outputName, MediaType="text/csv");
    result = labkit.ui.Result( ...
        Outputs={output}, Inputs=struct( ...
            "sources", state.project.inputs.sources), ...
        Parameters=state.project.parameters, ...
        Summary=struct("fileCount", numel(items)));
    written = context.writeResult(folder, result);
    state.project.results.lastExport = struct( ...
        "csvPath", outputPath, "manifestPath", string(written.Value));
    context.appendStatus("Exported CSV: " + outputPath);
end

function items = selectedItems(state)
    items = state.session.cache.items;
    indices = state.session.selection.files.Indices;
    indices = indices(indices <= numel(items));
    items = items(indices);
end
