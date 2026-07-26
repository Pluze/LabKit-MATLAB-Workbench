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
    state.session.cache.plotData, state.project.parameters.style, ...
    state.session.cache.sourceAxes);
cleanup = onCleanup(@() delete(fig));
filepath = string(chosen.Value);
if format == "fig"
    savefig(fig, filepath);
elseif format == "svg"
    exportgraphics(fig, char(filepath), ...
        'ContentType', 'vector', 'BackgroundColor', 'white', ...
        'Padding', 'figure');
else
    resolution = max(72, round( ...
        300 * state.project.parameters.style.exportScale));
    exportgraphics(fig, char(filepath), ...
        'Resolution', resolution, 'BackgroundColor', 'white', ...
        'Padding', 'figure');
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
callbackContext.log("info", "figure_studio.resultfiles.exportgraphic.status",  ...
    "Exported the current graphic.");
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
