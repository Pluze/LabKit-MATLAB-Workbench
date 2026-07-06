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
        labkit.ui.app.showAlert(services.figure, ...
            "No preview axes content is available to save.", "Figure Studio");
        return;
    end
    [filepath, cancelled] = labkit.ui.app.promptOutputFile( ...
        {'*.fig', 'MATLAB figure (*.fig)'}, "Save FIG", ...
        quickExportPath(state, ".fig"));
    if cancelled
        return;
    end
    tempFig = figure('Visible', 'off', 'Color', 'w');
    cleanup = onCleanup(@() delete(tempFig));
    dst = axes('Parent', tempFig);
    copyAxesToPreview(ax, dst);
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
            copyAxesToPreview(ax, previewAxes(services.ui));
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
        end
    catch
    end
end

function state = onFiguresChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
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
    paths = labkit.ui.view.filePaths(payload.event.removedFiles);
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
        cla(previewAxes(services.ui), 'reset');
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
    cla(previewAxes(services.ui), 'reset');
    state.summary = summaryLines(state);
end

function state = onSelectionChanged(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.selectedFiles);
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
        sourceStyle = importFigFile(item.path, previewAxes(services.ui));
        state = adoptSourceStyle(state, sourceStyle);
        state.currentSource = string(item.path);
        state = applyStyleToPreviewIfReady(state, services);
        state.status = "Opened " + string(item.name) + ".";
        state.summary = summaryLines(state);
        addLog(services, "Opened FIG: " + string(item.path));
    catch ME
        reportException(services, "Open FIG", ME);
        labkit.ui.app.showAlert(services.figure, ME.message, "Open FIG");
    end
end

function state = onStyleChanged(state, ~, services)
    state.preset = string(labkit.ui.view.getValue(services.ui, "stylePreset"));
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
    state.aspectPreset = string(labkit.ui.view.getValue(services.ui, "aspectPreset"));
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
    state.status = "Styled with " + state.preset + ".";
end

function state = onChooseOutputFolder(state, ~, services)
    [selected, cancelled] = labkit.ui.app.promptOutputFolder( ...
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
        labkit.ui.app.showAlert(services.figure, ...
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
        labkit.ui.app.showAlert(services.figure, ME.message, "Export package");
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
    baseFontSize = finiteValue(labkit.ui.view.getValue(ui, "baseFontSize"), previousBase);
    titleFontSize = finiteValue(labkit.ui.view.getValue(ui, "titleFontSize"), style.titleFontSize);
    labelFontSize = finiteValue(labkit.ui.view.getValue(ui, "labelFontSize"), style.labelFontSize);
    tickFontSize = finiteValue(labkit.ui.view.getValue(ui, "tickFontSize"), style.tickFontSize);
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
    style.dataLineWidth = finiteValue(labkit.ui.view.getValue(ui, "dataLineWidth"), 1.5);
    style.axesLineWidth = finiteValue(labkit.ui.view.getValue(ui, "axesLineWidth"), 1.25);
    style.gridAlpha = min(max(finiteValue(labkit.ui.view.getValue(ui, "gridAlpha"), 0.12), 0), 1);
    style.gridVisible = string(labkit.ui.view.getValue(ui, "gridVisible")) == "On";
    style.canvasWidth = finiteValue(labkit.ui.view.getValue(ui, "canvasWidth"), 1200);
    style.canvasHeight = finiteValue(labkit.ui.view.getValue(ui, "canvasHeight"), 900);
    style.exportScale = finiteValue(labkit.ui.view.getValue(ui, "exportScale"), 2);
    style.boundaryLines = string(labkit.ui.view.getValue(ui, "boundaryLines")) == "On";
    style = applyAspectPreset(style, aspectPreset, changedId);
end

function state = onQuickExport(state, ~, services, format)
    ax = previewAxes(services.ui);
    if ~hasPreviewContent(ax)
        labkit.ui.app.showAlert(services.figure, ...
            "No preview axes content is available to export.", "Figure Studio");
        return;
    end
    ext = "." + format;
    filepath = quickExportPath(state, ext);
    [filepath, cancelled] = labkit.ui.app.promptOutputFile( ...
        {char("*" + ext), char(upper(format) + " file")}, ...
        "Export " + upper(format), filepath);
    if cancelled
        return;
    end
    try
        figure_studio.resultFiles.applyFigureStyle(ax, state.style);
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
    catch ME
        figure_studio.resultFiles.applyFigureStyle(ax, previewStyle(state.style));
        reportException(services, "Quick export", ME);
        labkit.ui.app.showAlert(services.figure, ME.message, "Quick export");
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

function sourceStyle = importFigFile(filepath, dstAx)
    srcFig = openfig(char(filepath), 'invisible');
    cleanup = onCleanup(@() delete(srcFig));
    axesHandles = findobj(srcFig, 'Type', 'axes');
    axesHandles = axesHandles(~strcmp(get(axesHandles, 'Tag'), 'legend'));
    if isempty(axesHandles)
        error('labkit_FigureStudio_app:NoAxes', ...
            'The selected FIG file does not contain axes.');
    end
    srcAx = axesHandles(1);
    sourceStyle = sourceAxesStyle(srcAx);
    copyAxesToPreview(srcAx, dstAx);
end

function copyAxesToPreview(srcAx, dstAx)
    cla(dstAx, 'reset');
    dstAx.Visible = 'on';
    disableDefaultAxesToolbar(dstAx);
    copyAxesState(srcAx, dstAx);
    children = flipud(srcAx.Children(:));
    if ~isempty(children)
        copyobj(children, dstAx);
    end
    title(dstAx, string(srcAx.Title.String), 'Interpreter', 'none');
    xlabel(dstAx, string(srcAx.XLabel.String), 'Interpreter', 'none');
    ylabel(dstAx, string(srcAx.YLabel.String), 'Interpreter', 'none');
    zlabel(dstAx, string(srcAx.ZLabel.String), 'Interpreter', 'none');
    labkit.ui.tool.enableAxesPopout(dstAx);
end

function disableDefaultAxesToolbar(ax)
    try
        ax.Toolbar.Visible = 'off';
        disableDefaultInteractivity(ax);
    catch
    end
end

function copyAxesState(srcAx, dstAx)
    props = {'XScale','YScale','ZScale','XDir','YDir','ZDir', ...
        'XLim','YLim','ZLim','CLim','View','Box','XGrid','YGrid','ZGrid', ...
        'Color','XColor','YColor','ZColor','LineWidth','FontName','FontSize', ...
        'DataAspectRatio','DataAspectRatioMode', ...
        'PlotBoxAspectRatio','PlotBoxAspectRatioMode'};
    for k = 1:numel(props)
        try
            dstAx.(props{k}) = srcAx.(props{k});
        catch
        end
    end
    try
        colormap(dstAx, colormap(srcAx));
    catch
    end
end

function state = adoptSourceAxes(state, srcAx)
    state = adoptSourceStyle(state, sourceAxesStyle(srcAx));
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

function style = sourceAxesStyle(srcAx)
    style = figure_studio.styleLibrary.styleForPreset("FIG default");
    style.name = "FIG default";
    if isempty(srcAx) || ~isvalid(srcAx)
        return;
    end
    ratio = ratioFromVector(optionalAxesValue(srcAx, 'PlotBoxAspectRatio'));
    if ~isfinite(ratio)
        ratio = ratioFromPosition(srcAx);
    end
    width = 720;
    height = 540;
    if isfinite(ratio) && ratio > 0
        height = max(300, round(width / ratio));
    end
    style.canvasWidth = width;
    style.canvasHeight = height;
    style.fontName = string(optionalAxesValue(srcAx, 'FontName'));
    if strlength(style.fontName) == 0
        style.fontName = "Arial";
    end
    style.baseFontSize = finiteValue(optionalAxesValue(srcAx, 'FontSize'), 36);
    style.titleFontSize = sourceLabelFont(srcAx.Title, style.baseFontSize);
    style.labelFontSize = max([sourceLabelFont(srcAx.XLabel, style.baseFontSize), ...
        sourceLabelFont(srcAx.YLabel, style.baseFontSize), ...
        sourceLabelFont(srcAx.ZLabel, style.baseFontSize)]);
    style.tickFontSize = style.baseFontSize;
    style.dataLineWidth = sourceDataLineWidth(srcAx, 1.5);
    style.axesLineWidth = finiteValue(optionalAxesValue(srcAx, 'LineWidth'), 1.25);
    style.gridVisible = string(optionalAxesValue(srcAx, 'XGrid')) == "on" || ...
        string(optionalAxesValue(srcAx, 'YGrid')) == "on";
    style.gridAlpha = finiteValue(optionalAxesValue(srcAx, 'GridAlpha'), 0.12);
    style.boxVisible = string(optionalAxesValue(srcAx, 'Box')) == "on";
    style.boundaryLines = style.boxVisible;
end

function value = sourceLabelFont(labelHandle, fallback)
    value = fallback;
    try
        if ~isempty(labelHandle) && isvalid(labelHandle)
            value = finiteValue(labelHandle.FontSize, fallback);
        end
    catch
    end
end

function value = sourceDataLineWidth(ax, fallback)
    value = fallback;
    try
        children = findall(ax, '-property', 'LineWidth');
        widths = nan(numel(children), 1);
        count = 0;
        for k = 1:numel(children)
            child = children(k);
            if isempty(child) || ~isvalid(child) || child == ax
                continue;
            end
            try
                count = count + 1;
                widths(count) = double(child.LineWidth);
            catch
            end
        end
        widths = widths(1:count);
        widths = widths(isfinite(widths));
        if ~isempty(widths)
            value = median(widths);
        end
    catch
    end
end

function ratio = ratioFromVector(value)
    ratio = NaN;
    if isnumeric(value) && numel(value) >= 2 && ...
            all(isfinite(value(1:2))) && value(2) > 0
        ratio = double(value(1)) / double(value(2));
    end
end

function ratio = ratioFromPosition(ax)
    ratio = NaN;
    try
        pos = getpixelposition(ax, true);
        if numel(pos) >= 4 && all(isfinite(pos(3:4))) && pos(4) > 0
            ratio = double(pos(3)) / double(pos(4));
        end
    catch
    end
end

function value = optionalAxesValue(ax, prop)
    value = [];
    try
        value = ax.(prop);
    catch
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
    labkit.ui.view.appendLog(services.ui, 'appLog', char(string(msg)));
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
