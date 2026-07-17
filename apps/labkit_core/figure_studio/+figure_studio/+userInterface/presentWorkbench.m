% Expected caller: the LabKit V2 runtime. Input is canonical Figure Studio
% state. Output is deterministic controls and one serializable plot preview.
function view = presentWorkbench(state)
    sources = state.project.inputs.sources;
    parameters = state.project.parameters;
    hasFigure = ~isempty(state.session.cache.plotData);
    view = struct();
    view.controls.figFiles = fileSpec( ...
        sources, state.session.selection.currentIndex);
    view.controls.currentSource = valueSpec(state.session.cache.currentSource);
    view.controls.statusSummary = valueSpec(strjoin(summaryLines(state), " | "));
    for id = ["saveFig", "exportPng", "exportJpg", ...
            "exportSvg", "exportCurrent"]
        view.controls.(id) = enabledSpec(hasFigure);
    end
    view.controls.outputFolder = valueSpec(parameters.outputFolder);
    view.previews.preview.Axes.main = struct( ...
        "Renderer", "studioPlot", ...
        "Model", struct( ...
            "plotData", state.session.cache.plotData, ...
            "style", parameters.style, ...
            "preview", true));
end

function spec = fileSpec(sources, index)
    files = repmat(struct("id", "", "path", "", "status", "ready"), ...
        numel(sources), 1);
    paths = labkit.ui.runtime.sourcePaths(sources);
    for k = 1:numel(sources)
        files(k).id = string(sources(k).id);
        files(k).path = paths(k);
    end
    selection = strings(0, 1);
    if index >= 1 && index <= numel(sources)
        selection = string(sources(index).id);
    end
    spec = struct("Files", files, "Selection", selection);
end

function lines = summaryLines(state)
    lines = strings(0, 1);
    lines(end + 1, 1) = string(state.session.workflow.status);
    lines(end + 1, 1) = "Style mode: " + state.project.parameters.preset;
    style = state.project.parameters.style;
    lines(end + 1, 1) = sprintf([ ...
        'Fonts title/label/tick: %.0f / %.0f / %.0f | ' ...
        'line widths data/axes: %.2f / %.2f'], ...
        style.titleFontSize, style.labelFontSize, style.tickFontSize, ...
        style.dataLineWidth, style.axesLineWidth);
    if strlength(state.project.results.resultManifestPath) > 0
        lines(end + 1, 1) = "Last manifest: " + ...
            state.project.results.resultManifestPath;
    end
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end
