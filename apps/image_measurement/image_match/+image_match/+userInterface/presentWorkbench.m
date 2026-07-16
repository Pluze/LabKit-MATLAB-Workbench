% Expected caller: the LabKit V2 runtime. Input is canonical Image Match
% state. Output is deterministic controls and one registered image preview.
function view = presentWorkbench(state)
    [reference, sources] = sourceGroups(state.project.inputs.sources);
    p = state.project.parameters;
    steps = state.project.annotations.steps;
    ready = ~isempty(state.session.cache.currentItem) && ...
        ~isempty(state.session.cache.referenceItem);
    view = struct();
    view.controls.referenceImage = fileSpec(reference, 0, "No reference loaded");
    view.controls.sourceImages = fileSpec( ...
        sources, state.session.selection.currentIndex, sourceStatus(sources));
    view.controls.imageStatus = valueSpec(sprintf( ...
        'Images: %d | match steps: %d', numel(sources), numel(steps)));
    view.controls.matchMethod = valueSpec(p.matchMethod);
    view.controls.matchStrength = valueSpec(p.matchStrength);
    view.controls.toneStrength = valueSpec(p.toneStrength);
    view.controls.colorStrength = valueSpec(p.colorStrength);
    view.controls.matchFlow = valueSpec( ...
        image_match.userInterface.matchFlowLines(p.matchMethod));
    view.controls.applyMatch = enabledSpec(ready);
    view.controls.undoHistory = enabledSpec(~isempty(steps));
    view.controls.resetHistory = enabledSpec(~isempty(steps));
    view.controls.historyTable = dataSpec( ...
        image_match.userInterface.historyTableData(steps));
    view.controls.historyStatus = valueSpec(sprintf( ...
        'History steps: %d', numel(steps)));
    view.controls.metricsTable = dataSpec(metricData(state, steps));
    view.controls.outputFolder = valueSpec(p.outputFolder);
    view.controls.exportFormat = valueSpec(p.exportFormat);
    view.controls.exportImages = enabledSpec(ready);
    view.controls.exportDetails = valueSpec(detailLines(state, sources, reference));
    view.controls.preview = valueSpec(state.session.view.previewMode);
    view.previews.preview = struct("Renderer", "imagePreview", ...
        "Model", previewModel(state));
end

function spec = fileSpec(sources, index, status)
    files = repmat(struct("id", "", "path", "", "status", "ready"), ...
        numel(sources), 1);
    for k = 1:numel(sources)
        files(k).id = string(sources(k).id);
        files(k).path = string(sources(k).reference.originalPath);
    end
    selection = strings(0, 1);
    if index >= 1 && index <= numel(sources)
        selection = string(sources(index).id);
    end
    spec = struct();
    spec.Files = files;
    spec.Selection = selection;
    spec.Status = status;
end

function value = sourceStatus(sources)
    if isempty(sources)
        value = "No images loaded";
    else
        value = sprintf('%d image(s)', numel(sources));
    end
end

function data = metricData(state, steps)
    if isempty(state.session.cache.currentItem) || ...
            isempty(state.session.cache.previewResult)
        data = image_match.userInterface.resultTableData([], [], 0);
    else
        data = image_match.userInterface.resultTableData( ...
            state.session.cache.currentItem, ...
            state.session.cache.previewResult, numel(steps));
    end
end

function lines = detailLines(state, sources, reference)
    if isempty(sources)
        lines = {'Load a reference and one or more source images.'};
        return;
    end
    index = min(max(state.session.selection.currentIndex, 1), numel(sources));
    lines = {"Selected: " + displayName(sources(index)), ...
        "Source images: " + string(numel(sources)), ...
        "Reference: " + referenceName(reference), ...
        "History steps: " + string(numel(state.project.annotations.steps))};
    if strlength(state.project.results.resultManifestPath) > 0
        lines{end + 1} = "Last manifest: " + ...
            state.project.results.resultManifestPath;
    elseif ~isempty(state.project.results.lastExport)
        lines{end + 1} = "Last manifest: " + ...
            string(state.project.results.lastExport.manifestPath);
    end
    lines = cellstr(string(lines));
end

function model = previewModel(state)
    cache = state.session.cache;
    switch state.session.view.previewMode
        case "Original"
            imageData = cache.previewSource;
            titleText = "Original Preview";
        case "Before | After"
            imageData = image_match.userInterface.beforeAfterImage( ...
                cache.previewSource, cache.previewResult);
            titleText = "Before | After";
        otherwise
            imageData = cache.previewResult;
            titleText = "Matched Preview";
    end
    model = struct("imageData", imageData, "title", titleText);
end

function [reference, sources] = sourceGroups(allSources)
    roles = string({allSources.role});
    reference = allSources(roles == "reference-image");
    sources = allSources(roles == "source-image");
end

function value = referenceName(reference)
    if isempty(reference)
        value = "-";
    else
        value = displayName(reference(1));
    end
end

function value = displayName(source)
    [~, stem, extension] = fileparts(source.reference.originalPath);
    value = string(stem) + string(extension);
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = dataSpec(value)
    spec = struct();
    spec.Data = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end
