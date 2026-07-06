% App-owned action table for Figure Studio. Expected caller is
% figure_studio.definition. Handlers own FIG import, style parameter updates,
% preview mutation, and export package side effects.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "figuresChosen", @onFiguresChosen, ...
        "figuresRemoved", @onFiguresRemoved, ...
        "clearFigures", @onClearFigures, ...
        "selectionChanged", @onSelectionChanged, ...
        "styleChanged", @onStyleChanged, ...
        "styleParameterChanged", @onStyleParameterChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "saveFig", @onSaveFig, ...
        "exportPng", @(state, payload, services) onQuickExport(state, payload, services, "png"), ...
        "exportJpg", @(state, payload, services) onQuickExport(state, payload, services, "jpg"), ...
        "exportSvg", @(state, payload, services) onQuickExport(state, payload, services, "svg"), ...
        "exportCurrent", @onExportCurrent);
end

function state = onSaveFig(state, ~, services)
    ax = previewAxes(services.ui);
    if ~hasPreviewContent(ax)
        labkit.ui.runtime.showAlert(services.figure, ...
            "No preview axes content is available to save.", "Figure Studio");
        return;
    end
    [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        {'*.fig', 'MATLAB figure (*.fig)'}, "Save FIG", ...
        quickExportPath(state, ".fig"));
    if cancelled
        return;
    end
    tempFig = figure('Visible', 'off', 'Color', 'w');
    cleanup = onCleanup(@() delete(tempFig));
    dst = axes('Parent', tempFig);
    figure_studio.sourceAxes.copyToPreview(ax, dst);
    figure_studio.resultFiles.applyFigureStyle(dst, state.style);
    savefig(tempFig, char(filepath));
    clear cleanup;
    state.status = "Saved FIG: " + filepath;
    state.summary = summaryLines(state);
    addLog(services, state.status);
end

function state = onStartup(state, ~, services)
    installResizeHandler(services.figure);
    state = adoptLaunchRequest(state, services);
    if isfield(state, 'launchAxes') && ~isempty(state.launchAxes)
        ax = state.launchAxes;
        if ~isempty(ax) && isvalid(ax)
            state = adoptSourceAxes(state, ax);
            figure_studio.sourceAxes.copyToPreview(ax, previewAxes(services.ui));
            state.currentSource = "Popout axes";
            state.status = "Received copied axes from popout.";
            state = applyStyleToPreviewIfReady(state, services);
            state.summary = summaryLines(state);
            addLog(services, "Received axes from popout window.");
        end
        state.launchAxes = [];
    end
    if isDebugEnabled(services.debug)
        services.debug.trace('Figure Studio debug trace enabled.');
        try
            pack = figure_studio.debug.writeSamplePack(services.debug);
            addLog(services, "Debug sample FIG: " + string(pack.representativeFiles));
        catch ME
            services.debug.reportException('figureStudio', ...
                'Debug sample setup failed', ME);
        end
    end
end

function installResizeHandler(fig)
    try
        runtime = getappdata(fig, 'labkitUiAppRuntime');
        targets = resizeTargets(fig, runtime.ui);
        listeners = cell(1, numel(targets));
        for k = 1:numel(targets)
            listeners{k} = addlistener(targets{k}, 'Position', 'PostSet', ...
                @(~, event) onStudioResized(ancestor(event.AffectedObject, 'figure')));
        end
        setappdata(fig, 'labkitFigureStudioResizeListeners', listeners);
        resizeTimer = timer( ...
            'ExecutionMode', 'fixedSpacing', ...
            'Period', 0.25, ...
            'BusyMode', 'drop', ...
            'TimerFcn', @(timerObj, ~) pollStudioResize(timerObj, fig), ...
            'StopFcn', @(timerObj, ~) delete(timerObj));
        setappdata(fig, 'labkitFigureStudioResizeTimer', resizeTimer);
        start(resizeTimer);
    catch
    end
end

function pollStudioResize(timerObj, fig)
    if isempty(fig) || ~isvalid(fig)
        stop(timerObj);
        return;
    end
    try
        runtime = getappdata(fig, 'labkitUiAppRuntime');
        ax = runtime.ui.controls.preview.axesById.main;
        pos = getpixelposition(ax, true);
        key = 'labkitFigureStudioLastPreviewPosition';
        if isappdata(fig, key)
            previous = getappdata(fig, key);
            if isequal(round(previous), round(pos))
                return;
            end
        end
        setappdata(fig, key, pos);
        if hasPreviewContent(ax)
            figure_studio.resultFiles.applyFigureStyle(ax, previewStyle(runtime.state.style));
            clearFrameworkPreviewTitle(ax);
        end
    catch
    end
end

function targets = resizeTargets(fig, ui)
    targets = {fig};
    if isfield(ui, 'rightPanel') && isvalid(ui.rightPanel)
        targets{end + 1} = ui.rightPanel;
    end
    if isfield(ui.controls, 'preview')
        preview = ui.controls.preview;
        if isfield(preview, 'panel') && isvalid(preview.panel)
            targets{end + 1} = preview.panel;
        end
        if isfield(preview, 'axesGrid') && isvalid(preview.axesGrid)
            targets{end + 1} = preview.axesGrid;
        end
        if isfield(preview, 'primaryAxes') && isvalid(preview.primaryAxes)
            targets{end + 1} = preview.primaryAxes;
        end
    end
end

function onStudioResized(fig)
    try
        drawnow limitrate;
        runtime = getappdata(fig, 'labkitUiAppRuntime');
        if ~isstruct(runtime) || ~isfield(runtime, 'state') || ...
                ~isfield(runtime, 'ui')
            return;
        end
        ax = runtime.ui.controls.preview.axesById.main;
        if hasPreviewContent(ax)
            figure_studio.resultFiles.applyFigureStyle(ax, previewStyle(runtime.state.style));
            clearFrameworkPreviewTitle(ax);
        end
    catch
    end
end

function state = onFiguresChosen(state, payload, services)
    paths = labkit.ui.control.filePaths(payload.event.addedFiles);
    paths = paths(endsWith(lower(paths), ".fig"));
    if isempty(paths)
        addLog(services, "No FIG files selected.");
        return;
    end
    for k = 1:numel(paths)
        if ~isLoaded(state, paths(k))
            state.items(end + 1) = itemFromPath(paths(k));
        end
    end
    state.currentIndex = max(1, numel(state.items));
    state.status = sprintf('Loaded %d FIG file(s).', numel(state.items));
    state.summary = summaryLines(state);
    addLog(services, state.status);
    state = openCurrentItem(state, services);
end

function state = onFiguresRemoved(state, payload, services)
    paths = labkit.ui.control.filePaths(payload.event.removedFiles);
    if isempty(paths) || isempty(state.items)
        return;
    end
    keep = ~ismember(string({state.items.path}), string(paths(:)));
    state.items = state.items(keep);
    state.currentIndex = min(state.currentIndex, numel(state.items));
    if isempty(state.items)
        state.currentIndex = 0;
        state.currentSource = "";
        state.status = "No FIG files loaded.";
        labkit.ui.plot.reset(services.ui, 'preview', 'No figure loaded', true, 'main');
    else
        state = openCurrentItem(state, services);
    end
    state.summary = summaryLines(state);
end

function state = onClearFigures(state, ~, services)
    state.items = struct('path', {}, 'name', {}, 'source', {}, 'status', {});
    state.currentIndex = 0;
    state.currentSource = "";
    state.status = "No FIG files loaded.";
    labkit.ui.plot.reset(services.ui, 'preview', 'No figure loaded', true, 'main');
    state.summary = summaryLines(state);
end

function state = onSelectionChanged(state, payload, services)
    paths = labkit.ui.control.filePaths(payload.event.selectedFiles);
    if isempty(paths)
        return;
    end
    itemPaths = string({state.items.path});
    idx = find(itemPaths == paths(1), 1, 'first');
    if ~isempty(idx)
        state.currentIndex = idx;
        state = openCurrentItem(state, services);
    end
end

function state = openCurrentItem(state, services)
    item = currentItem(state);
    if isempty(item)
        return;
    end
    try
        sourceStyle = figure_studio.sourceAxes.importFigFile(item.path, ...
            previewAxes(services.ui));
        state = adoptSourceStyle(state, sourceStyle);
        state.currentSource = string(item.path);
        state = applyStyleToPreviewIfReady(state, services);
        state.status = "Opened " + string(item.name) + ".";
        state.summary = summaryLines(state);
        addLog(services, "Opened FIG: " + string(item.path));
    catch ME
        reportException(services, "Open FIG", ME);
        labkit.ui.runtime.showAlert(services.figure, ME.message, "Open FIG");
    end
end

function state = onStyleChanged(state, ~, services)
    state.preset = string(labkit.ui.control.getValue(services.ui, "stylePreset"));
    previousStyle = state.style;
    if state.preset == "FIG default"
        state.style = state.figDefaultStyle;
    else
        state.style = figure_studio.styleLibrary.styleForPreset(state.preset);
        state.style.canvasWidth = previousStyle.canvasWidth;
        state.style.canvasHeight = previousStyle.canvasHeight;
        state.style.exportScale = previousStyle.exportScale;
    end
    state = applyStyleToPreviewIfReady(state, services);
    state.summary = summaryLines(state);
    addLog(services, "Selected style mode: " + state.preset);
end

function state = onStyleParameterChanged(state, payload, services)
    changedId = changedControlId(payload);
    state.aspectPreset = string(labkit.ui.control.getValue(services.ui, "aspectPreset"));
    state.style = styleFromUi(state, services.ui, state.style, changedId, ...
        state.aspectPreset);
    state = applyStyleToPreviewIfReady(state, services);
    state.summary = summaryLines(state);
end

function state = applyStyleToPreviewIfReady(state, services)
    ax = previewAxes(services.ui);
    if ~hasPreviewContent(ax)
        return;
    end
    figure_studio.resultFiles.applyFigureStyle(ax, previewStyle(state.style));
    clearFrameworkPreviewTitle(ax);
    state.status = "Styled with " + state.preset + ".";
end

function state = onChooseOutputFolder(state, ~, services)
    [selected, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
        "Choose Figure Studio output folder", state.outputFolder);
    if cancelled
        return;
    end
    state.outputFolder = string(selected);
    addLog(services, "Output folder: " + state.outputFolder);
end

function state = onExportCurrent(state, ~, services)
    ax = previewAxes(services.ui);
    if ~hasPreviewContent(ax)
        labkit.ui.runtime.showAlert(services.figure, ...
            "No preview axes content is available to export.", "Figure Studio");
        return;
    end
    outFolder = string(fullfile(state.outputFolder, exportFolderName(state)));
    try
        manifest = figure_studio.resultFiles.exportAxesPackage(ax, outFolder);
        state.lastExportFolder = string(manifest.folder);
        state.status = "Exported package: " + string(manifest.folder);
        state.summary = summaryLines(state);
        addLog(services, state.status);
    catch ME
        reportException(services, "Export package", ME);
        labkit.ui.runtime.showAlert(services.figure, ME.message, "Export package");
    end
end

function style = styleFromUi(state, ui, previousStyle, changedId, aspectPreset)
    style = state.style;
    if nargin < 3 || isempty(previousStyle)
        previousStyle = style;
    end
    if nargin < 4
        changedId = "";
    end
    if nargin < 5
        aspectPreset = "Custom";
    end
    previousBase = finiteValue(previousStyle.baseFontSize, 12);
    baseFontSize = finiteValue(labkit.ui.control.getValue(ui, "baseFontSize"), previousBase);
    titleFontSize = finiteValue(labkit.ui.control.getValue(ui, "titleFontSize"), style.titleFontSize);
    labelFontSize = finiteValue(labkit.ui.control.getValue(ui, "labelFontSize"), style.labelFontSize);
    tickFontSize = finiteValue(labkit.ui.control.getValue(ui, "tickFontSize"), style.tickFontSize);
    baseChanged = changedId == "baseFontSize" || ...
        abs(baseFontSize - previousBase) > eps(previousBase);
    style.baseFontSize = baseFontSize;
    style = ensureFontOverrideFields(style);
    if baseChanged
        style.titleFontSize = baseFontSize;
        style.labelFontSize = baseFontSize;
        style.tickFontSize = baseFontSize;
        style.fontOverrides.title = false;
        style.fontOverrides.label = false;
        style.fontOverrides.tick = false;
    else
        style.titleFontSize = titleFontSize;
        style.labelFontSize = labelFontSize;
        style.tickFontSize = tickFontSize;
        style.fontOverrides.title = abs(titleFontSize - ...
            (baseFontSize + finiteValue(style.titleFontOffset, 2))) > eps(baseFontSize);
        style.fontOverrides.label = abs(labelFontSize - ...
            (baseFontSize + finiteValue(style.labelFontOffset, 0))) > eps(baseFontSize);
        style.fontOverrides.tick = abs(tickFontSize - ...
            (baseFontSize + finiteValue(style.tickFontOffset, -1))) > eps(baseFontSize);
    end
    style.dataLineWidth = finiteValue(labkit.ui.control.getValue(ui, "dataLineWidth"), 1.5);
    style.axesLineWidth = finiteValue(labkit.ui.control.getValue(ui, "axesLineWidth"), 1.25);
    style.gridAlpha = min(max(finiteValue(labkit.ui.control.getValue(ui, "gridAlpha"), 0.12), 0), 1);
    style.gridVisible = string(labkit.ui.control.getValue(ui, "gridVisible")) == "On";
    style.canvasWidth = finiteValue(labkit.ui.control.getValue(ui, "canvasWidth"), 1200);
    style.canvasHeight = finiteValue(labkit.ui.control.getValue(ui, "canvasHeight"), 900);
    style.exportScale = finiteValue(labkit.ui.control.getValue(ui, "exportScale"), 2);
    style.boundaryLines = string(labkit.ui.control.getValue(ui, "boundaryLines")) == "On";
    style = applyAspectPreset(style, aspectPreset, changedId);
end

function state = onQuickExport(state, ~, services, format)
    ax = previewAxes(services.ui);
    if ~hasPreviewContent(ax)
        labkit.ui.runtime.showAlert(services.figure, ...
            "No preview axes content is available to export.", "Figure Studio");
        return;
    end
    ext = "." + format;
    filepath = quickExportPath(state, ext);
    [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        {char("*" + ext), char(upper(format) + " file")}, ...
        "Export " + upper(format), filepath);
    if cancelled
        return;
    end
    try
        figure_studio.resultFiles.applyFigureStyle(ax, state.style);
        clearFrameworkPreviewTitle(ax);
        if format == "svg"
            exportgraphics(ax, filepath, "ContentType", "vector");
        else
            exportgraphics(ax, filepath, "Resolution", ...
                max(72, round(300 * state.style.exportScale)));
        end
        state.status = "Exported " + upper(format) + ": " + filepath;
        state.summary = summaryLines(state);
        addLog(services, state.status);
        figure_studio.resultFiles.applyFigureStyle(ax, previewStyle(state.style));
        clearFrameworkPreviewTitle(ax);
    catch ME
        figure_studio.resultFiles.applyFigureStyle(ax, previewStyle(state.style));
        clearFrameworkPreviewTitle(ax);
        reportException(services, "Quick export", ME);
        labkit.ui.runtime.showAlert(services.figure, ME.message, "Quick export");
    end
end

function clearFrameworkPreviewTitle(ax)
    try
        titleText = join(string(ax.Title.String), " ");
        if contains(titleText, " | file ") || startsWith(titleText, "file ")
            title(ax, "");
        end
    catch
    end
end

function state = adoptLaunchRequest(state, services)
    if ~isstruct(services) || ~isfield(services, 'request') || ...
            ~isstruct(services.request) || ~isfield(services.request, 'launch')
        return;
    end
    launchRequest = services.request.launch;
    if isstruct(launchRequest) && isfield(launchRequest, 'hasAxes') && ...
            logical(launchRequest.hasAxes)
        state.launchAxes = launchRequest.axes;
    end
end

function style = previewStyle(style)
    style.previewScale = true;
end

function filepath = quickExportPath(state, ext)
    folder = string(state.outputFolder);
    stem = "figure";
    if strlength(state.currentSource) > 0
        [~, stemValue] = fileparts(state.currentSource);
        if strlength(stemValue) > 0
            stem = string(matlab.lang.makeValidName(char(stemValue)));
        end
    end
    filepath = fullfile(folder, stem + ext);
end

function id = changedControlId(payload)
    id = "";
    if isstruct(payload) && isfield(payload, 'event') && ...
            isstruct(payload.event) && isfield(payload.event, 'id')
        id = string(payload.event.id);
    elseif isstruct(payload) && isfield(payload, 'control') && ...
            isstruct(payload.control) && isfield(payload.control, 'id')
        id = string(payload.control.id);
    end
end

function style = applyAspectPreset(style, preset, changedId)
    ratio = aspectRatio(preset);
    if isnan(ratio)
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

function style = ensureFontOverrideFields(style)
    if ~isfield(style, 'titleFontOffset')
        style.titleFontOffset = 2;
    end
    if ~isfield(style, 'labelFontOffset')
        style.labelFontOffset = 0;
    end
    if ~isfield(style, 'tickFontOffset')
        style.tickFontOffset = -1;
    end
    if ~isfield(style, 'fontOverrides') || ~isstruct(style.fontOverrides)
        style.fontOverrides = struct('title', false, 'label', false, 'tick', false);
    end
    for name = ["title", "label", "tick"]
        field = char(name);
        if ~isfield(style.fontOverrides, field)
            style.fontOverrides.(field) = false;
        end
    end
end

function value = finiteValue(value, fallback)
    value = double(value);
    if ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function state = adoptSourceAxes(state, srcAx)
    state = adoptSourceStyle(state, figure_studio.sourceAxes.sourceStyle(srcAx));
end

function state = adoptSourceStyle(state, sourceStyle)
    if ~isstruct(sourceStyle)
        return;
    end
    state.figDefaultStyle = sourceStyle;
    if state.preset == "FIG default"
        state.style = sourceStyle;
    elseif isfield(sourceStyle, 'canvasWidth') && isfield(sourceStyle, 'canvasHeight')
        state.style.canvasWidth = sourceStyle.canvasWidth;
        state.style.canvasHeight = sourceStyle.canvasHeight;
        state.aspectPreset = "Custom";
    end
end

function ax = previewAxes(ui)
    ax = ui.controls.preview.axesById.main;
end

function tf = hasPreviewContent(ax)
    tf = ~isempty(ax) && isvalid(ax) && ~isempty(ax.Children);
end

function item = itemFromPath(filepath)
    [~, name, ext] = fileparts(filepath);
    item = struct( ...
        'path', string(filepath), ...
        'name', string(name) + string(ext), ...
        'source', "fig", ...
        'status', "Ready");
end

function item = currentItem(state)
    item = [];
    if isempty(state.items)
        return;
    end
    idx = state.currentIndex;
    if isempty(idx) || idx < 1 || idx > numel(state.items)
        idx = 1;
    end
    item = state.items(idx);
end

function tf = isLoaded(state, filepath)
    tf = ~isempty(state.items) && any(string({state.items.path}) == string(filepath));
end

function name = exportFolderName(state)
    source = state.currentSource;
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

function lines = summaryLines(state)
    lines = strings(0, 1);
    lines(end + 1, 1) = string(state.status);
    lines(end + 1, 1) = "Style mode: " + string(state.preset);
    lines(end + 1, 1) = sprintf(['Fonts title/label/tick: %.0f / %.0f / %.0f | ' ...
        'line widths data/axes: %.2f / %.2f'], ...
        state.style.titleFontSize, state.style.labelFontSize, ...
        state.style.tickFontSize, state.style.dataLineWidth, ...
        state.style.axesLineWidth);
    if strlength(state.lastExportFolder) > 0
        lines(end + 1, 1) = "Last export: " + state.lastExportFolder;
    end
end

function addLog(services, msg)
    labkit.ui.control.appendLog(services.ui, 'appLog', char(string(msg)));
    if isDebugEnabled(services.debug)
        services.debug.append(string(msg));
    end
end

function reportException(services, event, ME)
    if isDebugEnabled(services.debug)
        services.debug.reportException('figureStudio', event, ME);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
