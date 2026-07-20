% App-owned implementation for figure_studio.resultFiles.exportGraphic within the figure_studio product workflow.
function state = exportGraphic(state, callbackContext, format)
%EXPORTGRAPHIC Write one styled graphic and its standard result manifest.
arguments
    state (1, 1) struct
    callbackContext (1, 1) labkit.app.CallbackContext
    format (1, 1) string
end
if isempty(state.session.cache.plotData)
    callbackContext.alert( ...
        "No preview axes content is available to export.", "Figure Studio");
    return
end
extension = "." + format;
chosen = callbackContext.chooseOutputFile( ...
    ["*" + extension, upper(format) + " file"], ...
    quickExportStartPath(state));
if chosen.Cancelled
    return
end
[fig, ax] = figure_studio.resultFiles.createStyledFigure( ...
    state.session.cache.plotData, state.project.parameters.style);
cleanup = onCleanup(@() delete(fig));
filepath = string(chosen.Value);
if format == "fig"
    savefig(fig, filepath);
elseif format == "svg"
    exportgraphics(ax, filepath, ContentType="vector");
else
    resolution = max(72, round( ...
        300 * state.project.parameters.style.exportScale));
    exportgraphics(ax, filepath, Resolution=resolution);
end
[folder, base, suffix] = fileparts(filepath);
output = labkit.app.result.File( ...
    "styledFigure", "primary", string(base) + string(suffix), ...
    MediaType=mediaType(format));
package = labkit.app.result.Package(Outputs={output}, ...
    Inputs=struct("sources", state.project.inputs.sources), ...
    Parameters=state.project.parameters, ...
    Summary=struct("format", format), ...
    ManifestName="figure_studio.labkit.json");
written = callbackContext.writeResultPackage(folder, package);
state.project.results.lastExport = struct( ...
    "kind", format, "path", filepath, ...
    "manifestPath", string(written.Value));
state.project.results.resultManifestPath = string(written.Value);
callbackContext.appendStatus( ...
    "Exported " + upper(format) + ": " + filepath);
end

function startPath = quickExportStartPath(state)
startPath = state.project.parameters.outputFolder;
if strlength(startPath) == 0
    source = state.session.cache.currentSource;
    if strlength(source) > 0 && isfile(source)
        startPath = string(fileparts(source));
    else
        startPath = pwd;
    end
end
end

function value = mediaType(format)
switch format
    case "fig"
        value = "application/x-matlab-figure";
    case "png"
        value = "image/png";
    case "jpg"
        value = "image/jpeg";
    case "svg"
        value = "image/svg+xml";
end
end
