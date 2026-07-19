% App-owned state handlers for Chrono Overlay. Standard bindings, file collection,
% project persistence, and resource cleanup remain runtime-owned.
function handlers = stateHandlers()
    handlers = struct( ...
        "exportCSV", labkit.app.StateHandler("exportCSV", @onExportCSV));
end

function state = onExportCSV(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
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
    output = labkit.app.result.File( ...
        "overlayCurves", "primary", outputName, MediaType="text/csv");
    result = labkit.app.result.Package( ...
        Outputs={output}, Inputs=struct( ...
            "sources", state.project.inputs.sources), ...
        Parameters=state.project.parameters, ...
        Summary=struct("fileCount", numel(items)));
    written = context.writeResultPackage(folder, result);
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
