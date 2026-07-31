% App-owned implementation for figure_studio.resultFiles.exportCurrent within the figure_studio product workflow.
function state = exportCurrent(state, callbackContext)
%EXPORTCURRENT Write visible data, reconstruction script, and provenance.
arguments
    state (1, 1) struct
    callbackContext (1, 1) labkit.app.CallbackContext
end
if isempty(state.session.cache.plotData)
    callbackContext.alert( ...
        "No preview axes content is available to export.", "Figure Studio");
    return
end
root = state.project.parameters.outputFolder;
if strlength(root) == 0
    chosen = callbackContext.chooseOutputFolder(pwd);
    if chosen.Cancelled
        return
    end
    root = string(chosen.Value);
end
folder = string(fullfile(root, exportFolderName(state)));
[fig, ax] = figure_studio.resultFiles.createStyledFigure( ...
    state.session.cache.plotData, state.project.parameters.style);
cleanup = onCleanup(@() delete(fig));
payload = figure_studio.resultFiles.exportAxesPackage(ax, folder);
outputs = packageOutputs(payload);
package = labkit.app.result.Package(Outputs=outputs, ...
    Inputs=struct("sources", state.project.inputs.sources), ...
    Parameters=state.project.parameters, ...
    Summary=struct( ...
        "objectCount", numel(state.session.cache.plotData.objects)), ...
    Warnings=payload.warnings, ...
    ManifestName="figure_studio.labkit.json");
written = callbackContext.writeResultPackage(folder, package);
state.project.parameters.outputFolder = root;
state.project.results.lastExport = struct( ...
    "kind", "package", "path", folder, ...
    "manifestPath", string(written.Value), "outputs", payload);
state.project.results.resultManifestPath = string(written.Value);
callbackContext.log("info", "figure_studio.resultfiles.exportcurrent.status", ...
    "Exported the Figure Studio package.");
end

function outputs = packageOutputs(payload)
outputs = { ...
    resultFile("plotData", "primary", payload.mat, ...
        "application/x-matlab-data"), ...
    resultFile("recreateScript", "reconstruction", payload.script, ...
        "text/x-matlab"), ...
    resultFile("readme", "documentation", payload.readme, ...
        "text/plain")};
if strlength(payload.csv) > 0
    outputs{end + 1} = resultFile( ...
        "plotCsv", "tabular", payload.csv, "text/csv");
end
end

function output = resultFile(id, role, filepath, mediaType)
[~, name, extension] = fileparts(filepath);
output = labkit.app.result.File(id, role, ...
    string(name) + string(extension), MediaType=mediaType);
end

function name = exportFolderName(state)
source = state.session.cache.currentSource;
if strlength(source) == 0
    source = "figure";
end
[~, stem] = fileparts(source);
if strlength(stem) == 0
    stem = "figure";
end
name = string(matlab.lang.makeValidName(char(stem))) + "_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
end
