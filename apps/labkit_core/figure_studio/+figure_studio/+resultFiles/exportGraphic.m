% App-owned implementation for figure_studio.resultFiles.exportGraphic within the figure_studio product workflow.
function state = exportGraphic(state, callbackContext, format)
%EXPORTGRAPHIC Write one App-owned styled graphic.
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
[fig, ~] = figure_studio.resultFiles.createStyledFigure( ...
    state.session.cache.plotData, state.project.parameters.style, ...
    state.session.cache.sourceAxes);
cleanup = onCleanup(@() delete(fig));
filepath = string(chosen.Value);
if format == "fig"
    savefig(fig, filepath);
elseif format == "svg"
    writeSvg(fig, filepath);
else
    resolution = max(72, round( ...
        300 * state.project.parameters.style.exportScale));
    writeRaster(fig, filepath, format, resolution);
end
state.project.results.lastExport = struct( ...
    "kind", format, "path", filepath, ...
    "outputPath", filepath);
state.project.results.lastOutputPath = filepath;
callbackContext.log("info", "figure_studio.resultfiles.exportgraphic.status",  ...
    "Exported the current graphic.");
end

function writeSvg(fig, filepath)
% R2022b-R2024b use print because exportgraphics gained SVG in R2025a.
if isMATLABReleaseOlderThan("R2025a")
    print(fig, char(filepath), '-dsvg');
else
    exportgraphics(fig, char(filepath), ...
        'ContentType', 'vector', 'BackgroundColor', 'white', ...
        'Padding', 'figure');
end
end

function writeRaster(fig, filepath, format, resolution)
% Preserve the complete figure canvas on releases without Padding="figure".
if ~isMATLABReleaseOlderThan("R2025a")
    exportgraphics(fig, char(filepath), ...
        'Resolution', resolution, 'BackgroundColor', 'white', ...
        'Padding', 'figure');
    return;
end
paperMode = fig.PaperPositionMode;
invertHardcopy = fig.InvertHardcopy;
cleanup = onCleanup(@() restorePrintProperties( ...
    fig, paperMode, invertHardcopy));
fig.PaperPositionMode = "auto";
fig.InvertHardcopy = "off";
device = "-d" + format;
if format == "jpg"
    device = "-djpeg";
end
print(fig, char(filepath), char(device), ...
    char("-r" + string(resolution)));
clear cleanup
end

function restorePrintProperties(fig, paperMode, invertHardcopy)
if isempty(fig) || ~isvalid(fig)
    return;
end
fig.PaperPositionMode = paperMode;
fig.InvertHardcopy = invertHardcopy;
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
