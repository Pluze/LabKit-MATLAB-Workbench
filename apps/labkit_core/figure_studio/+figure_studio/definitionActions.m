% App-owned V2 actions for Figure Studio. Handlers own FIG source snapshots,
% durable styles, serializable plot models, and exports without UI access.
function actions = definitionActions()
    actions = struct( ...
        "figuresChosen", @onFiguresChosen, ...
        "figuresRemoved", @onFiguresRemoved, ...
        "clearFigures", @onClearFigures, ...
        "selectionChanged", @onSelectionChanged, ...
        "styleChanged", @onStyleChanged, ...
        "styleParameterChanged", @onStyleParameterChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "saveFig", @onSaveFig, ...
        "exportPng", @onExportPng, ...
        "exportJpg", @onExportJpg, ...
        "exportSvg", @onExportSvg, ...
        "exportCurrent", @onExportCurrent);
end

function state = onFiguresChosen(state, event, services)
    paths = services.events.paths(event, "files");
    added = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = added;
    end
    paths = paths(endsWith(lower(paths), ".fig"));
    if isempty(paths)
        state = services.workflow.log(state, "No FIG files selected.");
        return;
    end
    sources = services.project.reconcileSources( ...
        state.project.inputs.sources, paths, "matlab-figure", "figure", true);
    index = selectedIndex(sources, added);
    [candidate, loaded] = loadSource(state, sources, index, services);
    if ~loaded
        return;
    end
    state = candidate;
    state.project.inputs.sources = sources;
    state.project.annotations.embeddedPlot = [];
    state.project.parameters.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(paths, "figure_studio", ...
        state.project.parameters.outputFolder));
    state.session.workflow.status = sprintf( ...
        'Loaded %d FIG file(s).', numel(sources));
    state = invalidateExport(state);
    state = services.workflow.log(state, state.session.workflow.status);
end

function state = onFiguresRemoved(state, event, services)
    sources = state.project.inputs.sources;
    indices = services.events.indices(event, "removedFiles", numel(sources));
    if isempty(indices)
        return;
    end
    sources(indices) = [];
    state.project.inputs.sources = sources;
    state.project.annotations.embeddedPlot = [];
    if isempty(sources)
        state = clearCurrentPlot(state, "No FIG files loaded.");
    else
        index = min(max(state.session.selection.currentIndex, 1), numel(sources));
        [state, ~] = loadSource(state, sources, index, services);
    end
    state = invalidateExport(state);
end

function state = onClearFigures(state, ~, services)
    state.project.inputs.sources = state.project.inputs.sources([]);
    state.project.annotations.embeddedPlot = [];
    state = clearCurrentPlot(state, "No FIG files loaded.");
    state = invalidateExport(state);
    state = services.workflow.log(state, "Cleared Figure Studio sources.");
end

function state = onSelectionChanged(state, event, services)
    sources = state.project.inputs.sources;
    indices = services.events.indices(event, "selectedFiles", numel(sources));
    if isempty(indices)
        return;
    end
    [state, ~] = loadSource(state, sources, indices(1), services);
end

function [state, loaded] = loadSource(state, sources, index, services)
    loaded = false;
    try
        [plotData, sourceStyle] = figure_studio.sourceAxes.readFigFile( ...
            sources(index).reference.originalPath);
    catch ME
        state = reportFailure(state, services, "Open FIG", ME);
        return;
    end
    state.session.selection.currentIndex = index;
    state.session.cache.plotData = plotData;
    state.session.cache.sourceDefaultStyle = sourceStyle;
    state.session.cache.currentSource = string( ...
        sources(index).reference.originalPath);
    state.project.annotations.sourceDefaultStyle = sourceStyle;
    state = adoptSourceStyle(state, sourceStyle);
    state.session.workflow.status = "Opened " + ...
        string(sources(index).reference.fileName) + ".";
    state = services.workflow.log(state, ...
        "Opened FIG: " + state.session.cache.currentSource);
    loaded = true;
end

function state = clearCurrentPlot(state, status)
    state.session.selection.currentIndex = 0;
    state.session.cache.plotData = [];
    state.session.cache.currentSource = "";
    state.session.workflow.status = string(status);
end

function state = adoptSourceStyle(state, sourceStyle)
    p = state.project.parameters;
    if p.preset == "FIG default"
        p.style = sourceStyle;
    else
        p.style.canvasWidth = sourceStyle.canvasWidth;
        p.style.canvasHeight = sourceStyle.canvasHeight;
        p.aspectPreset = "Custom";
    end
    p.gridChoice = onOff(p.style.gridVisible);
    p.boundaryChoice = onOff(p.style.boundaryLines);
    state.project.parameters = p;
end

function state = onStyleChanged(state, ~, services)
    p = state.project.parameters;
    previous = p.style;
    if p.preset == "FIG default"
        p.style = state.session.cache.sourceDefaultStyle;
    else
        p.style = figure_studio.styleLibrary.styleForPreset(p.preset);
        p.style.canvasWidth = previous.canvasWidth;
        p.style.canvasHeight = previous.canvasHeight;
        p.style.exportScale = previous.exportScale;
    end
    p.gridChoice = onOff(p.style.gridVisible);
    p.boundaryChoice = onOff(p.style.boundaryLines);
    state.project.parameters = p;
    state.session.workflow.status = "Styled with " + p.preset + ".";
    state = invalidateExport(state);
    state = services.workflow.log(state, ...
        "Selected style mode: " + p.preset);
end

function state = onStyleParameterChanged(state, event, ~)
    p = state.project.parameters;
    id = string(event.target);
    p.style = sanitizeStyle(p.style);
    if id == "baseFontSize"
        p.style.titleFontSize = p.style.baseFontSize;
        p.style.labelFontSize = p.style.baseFontSize;
        p.style.tickFontSize = p.style.baseFontSize;
        p.style = clearFontOverrides(p.style);
    elseif any(id == ["titleFontSize", "labelFontSize", "tickFontSize"])
        p.style = markFontOverride(p.style, id);
    elseif id == "gridVisible"
        p.style.gridVisible = p.gridChoice == "On";
    elseif id == "boundaryLines"
        p.style.boundaryLines = p.boundaryChoice == "On";
    end
    p.style = applyAspectPreset(p.style, p.aspectPreset, id);
    state.project.parameters = p;
    state.session.workflow.status = "Styled with " + p.preset + ".";
    state = invalidateExport(state);
end

function state = onChooseOutputFolder(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        "Choose Figure Studio output folder", ...
        state.project.parameters.outputFolder);
    if cancelled
        return;
    end
    state.project.parameters.outputFolder = string(folder);
    state = invalidateExport(state);
    state = services.workflow.log(state, "Output folder: " + string(folder));
end

function state = onSaveFig(state, ~, services)
    if ~hasPlot(state)
        services.dialogs.alert( ...
            "No preview axes content is available to save.", "Figure Studio");
        return;
    end
    [filepath, cancelled] = services.dialogs.outputFile( ...
        {'*.fig', 'MATLAB figure (*.fig)'}, "Save FIG", ...
        quickExportPath(state, ".fig"));
    if cancelled
        return;
    end
    try
        [fig, ~] = styledFigure(state);
        cleanup = onCleanup(@() delete(fig));
        savefig(fig, char(filepath));
        [manifestPath, outputs] = writeSingleManifest( ...
            state, services, filepath, "matlab-figure", ...
            "application/x-matlab-figure");
    catch ME
        state = reportFailure(state, services, "Save FIG", ME);
        return;
    end
    state = recordExport(state, "fig", filepath, manifestPath, outputs);
    state = services.workflow.log(state, "Saved FIG: " + string(filepath));
end

function state = onExportPng(state, ~, services)
    state = onQuickExport(state, services, "png", "image/png");
end

function state = onExportJpg(state, ~, services)
    state = onQuickExport(state, services, "jpg", "image/jpeg");
end

function state = onExportSvg(state, ~, services)
    state = onQuickExport(state, services, "svg", "image/svg+xml");
end

function state = onQuickExport(state, services, format, mediaType)
    if ~hasPlot(state)
        services.dialogs.alert( ...
            "No preview axes content is available to export.", "Figure Studio");
        return;
    end
    extension = "." + format;
    [filepath, cancelled] = services.dialogs.outputFile( ...
        {char("*" + extension), char(upper(format) + " file")}, ...
        "Export " + upper(format), quickExportPath(state, extension));
    if cancelled
        return;
    end
    try
        [fig, ax] = styledFigure(state);
        cleanup = onCleanup(@() delete(fig));
        if format == "svg"
            exportgraphics(ax, filepath, 'ContentType', 'vector');
        else
            exportgraphics(ax, filepath, 'Resolution', ...
                max(72, round(300 * state.project.parameters.style.exportScale)));
        end
        [manifestPath, outputs] = writeSingleManifest( ...
            state, services, filepath, format, mediaType);
    catch ME
        state = reportFailure(state, services, "Quick export", ME);
        return;
    end
    state = recordExport(state, format, filepath, manifestPath, outputs);
    state = services.workflow.log(state, ...
        "Exported " + upper(format) + ": " + string(filepath));
end

function state = onExportCurrent(state, ~, services)
    if ~hasPlot(state)
        services.dialogs.alert( ...
            "No preview axes content is available to export.", "Figure Studio");
        return;
    end
    folder = fullfile(state.project.parameters.outputFolder, ...
        exportFolderName(state));
    try
        [fig, ax] = styledFigure(state);
        cleanup = onCleanup(@() delete(fig));
        payload = figure_studio.resultFiles.exportAxesPackage(ax, folder);
        outputs = packageOutputs(payload, services);
        spec = manifestSpec(state, outputs);
        [manifestPath, ~] = services.results.writeManifest(folder, spec);
    catch ME
        state = reportFailure(state, services, "Export package", ME);
        return;
    end
    state = recordExport(state, "package", folder, manifestPath, outputs);
    state = services.workflow.log(state, ...
        "Exported package: " + string(folder));
end

function [fig, ax] = styledFigure(state)
    [fig, ax] = figure_studio.resultFiles.createStyledFigure( ...
        state.session.cache.plotData, state.project.parameters.style);
end

function [manifestPath, outputs] = writeSingleManifest( ...
        state, services, filepath, role, mediaType)
    [folder, name, extension] = fileparts(filepath);
    outputs = services.results.output(role, role, ...
        string(name) + string(extension), mediaType);
    [manifestPath, ~] = services.results.writeManifest( ...
        string(folder), manifestSpec(state, outputs));
end

function spec = manifestSpec(state, outputs)
    plotData = state.session.cache.plotData;
    spec = struct( ...
        "Outputs", outputs, ...
        "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", struct( ...
            "objectCount", numel(plotData.objects), ...
            "warningCount", numel(plotData.warnings)), ...
        "ManifestName", "figure_studio.labkit.json");
end

function outputs = packageOutputs(payload, services)
    paths = [payload.mat; payload.script; payload.readme];
    roles = ["plot-data", "recreation-script", "readme"];
    media = ["application/x-matlab-data", "text/x-matlab", "text/plain"];
    if strlength(payload.csv) > 0
        paths(end + 1, 1) = payload.csv;
        roles(end + 1, 1) = "plot-data-csv";
        media(end + 1, 1) = "text/csv";
    end
    outputs = services.results.emptyOutputs();
    for k = 1:numel(paths)
        [~, name, extension] = fileparts(paths(k));
        outputs(end + 1, 1) = services.results.output(roles(k), roles(k), ...
            string(name) + string(extension), media(k));
    end
end

function state = recordExport(state, kind, path, manifestPath, outputs)
    state.project.results.lastExport = struct( ...
        "kind", string(kind), ...
        "path", string(path), ...
        "outputs", outputs, ...
        "manifestPath", string(manifestPath));
    state.project.results.resultManifestPath = string(manifestPath);
    state.session.workflow.status = "Exported " + string(kind) + ".";
end

function state = invalidateExport(state)
    state.project.results.lastExport = [];
    state.project.results.resultManifestPath = "";
end

function tf = hasPlot(state)
    tf = ~isempty(state.session.cache.plotData);
end

function index = selectedIndex(sources, added)
    index = max(1, numel(sources));
    if isempty(added)
        return;
    end
    for k = 1:numel(sources)
        if string(sources(k).reference.originalPath) == string(added(end))
            index = k;
            return;
        end
    end
end

function style = sanitizeStyle(style)
    defaults = figure_studio.styleLibrary.styleForPreset("LabKit figure");
    names = ["baseFontSize", "titleFontSize", "labelFontSize", ...
        "tickFontSize", "dataLineWidth", "axesLineWidth", ...
        "gridAlpha", "canvasWidth", "canvasHeight", "exportScale"];
    for name = names
        field = char(name);
        style.(field) = finiteValue(style.(field), defaults.(field));
    end
    style.gridAlpha = min(max(style.gridAlpha, 0), 1);
    style.canvasWidth = min(max(style.canvasWidth, 400), 8000);
    style.canvasHeight = min(max(style.canvasHeight, 300), 8000);
    style.exportScale = min(max(style.exportScale, 1), 8);
end

function style = clearFontOverrides(style)
    style = ensureFontOverrides(style);
    style.fontOverrides.title = false;
    style.fontOverrides.label = false;
    style.fontOverrides.tick = false;
end

function style = markFontOverride(style, id)
    style = ensureFontOverrides(style);
    names = struct("titleFontSize", "title", ...
        "labelFontSize", "label", "tickFontSize", "tick");
    style.fontOverrides.(names.(char(id))) = true;
end

function style = ensureFontOverrides(style)
    if ~isfield(style, 'fontOverrides') || ~isstruct(style.fontOverrides)
        style.fontOverrides = struct( ...
            "title", false, "label", false, "tick", false);
    end
end

function style = applyAspectPreset(style, preset, changedId)
    ratio = aspectRatio(preset);
    if ~isfinite(ratio)
        return;
    end
    if changedId == "aspectPreset" || changedId == "canvasWidth"
        style.canvasHeight = max(1, round(style.canvasWidth / ratio));
    elseif changedId == "canvasHeight"
        style.canvasWidth = max(1, round(style.canvasHeight * ratio));
    end
end

function ratio = aspectRatio(preset)
    switch string(preset)
        case "4:3"
            ratio = 4 / 3;
        case "16:9"
            ratio = 16 / 9;
        case "1:1"
            ratio = 1;
        case "3:2"
            ratio = 3 / 2;
        otherwise
            ratio = NaN;
    end
end

function filepath = quickExportPath(state, extension)
    stem = "figure";
    source = state.session.cache.currentSource;
    if strlength(source) > 0
        [~, sourceStem] = fileparts(source);
        if strlength(sourceStem) > 0
            stem = string(matlab.lang.makeValidName(char(sourceStem)));
        end
    end
    filepath = fullfile(state.project.parameters.outputFolder, stem + extension);
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
    name = matlab.lang.makeValidName(char(stem)) + "_" + ...
        string(datestr(now, 'yyyymmdd_HHMMSS'));
end

function value = onOff(tf)
    if tf
        value = "On";
    else
        value = "Off";
    end
end

function value = finiteValue(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function state = reportFailure(state, services, context, exception)
    services.diagnostics.report(context, exception);
    services.dialogs.alert(exception.message, context);
    state.session.workflow.status = context + " failed.";
    state = services.workflow.log(state, context + ": " + exception.message);
end
