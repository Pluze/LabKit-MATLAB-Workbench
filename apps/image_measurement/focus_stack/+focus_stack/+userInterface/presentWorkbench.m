% Expected caller: the LabKit V2 runtime. Input is canonical Focus Stack
% state. Output is deterministic controls and paired image previews.
function view = presentWorkbench(state)
    sources = state.project.inputs.sources;
    images = state.session.cache.images;
    cacheResult = state.session.cache.result;
    durableResult = state.project.results.lastRun;
    hasSources = ~isempty(sources);
    hasStack = numel(images) >= 2;
    hasResult = cacheResult.ok;

    view = struct();
    view.controls.sourceLocation = valueSpec(sourceDescription(sources));
    view.controls.sourceImages = fileSpec(sources);
    view.controls.runFocusStack = enabledSpec(hasStack);
    view.controls.exportFused = enabledSpec(hasResult);
    view.controls.exportFocusMap = enabledSpec(hasResult);
    view.controls.exportSummary = enabledSpec(hasResult);
    view.controls.resultTable = dataSpec(resultTableData( ...
        cacheResult, durableResult));
    view.controls.details = valueSpec(detailLines(state, hasSources, hasStack));
    view.controls.logPanel = valueSpec(cellstr(state.session.workflow.logLines));
    [fusedModel, mapModel] = previewModels(images, cacheResult);
    view.previews.preview.Axes.fused = struct( ...
        "Renderer", "focusImage", "Model", fusedModel);
    view.previews.preview.Axes.focusMap = struct( ...
        "Renderer", "focusImage", "Model", mapModel);
end

function spec = fileSpec(sources)
    files = repmat(struct("id", "", "path", "", "status", "ready"), ...
        numel(sources), 1);
    for k = 1:numel(sources)
        files(k).id = string(sources(k).id);
        files(k).path = string(sources(k).reference.originalPath);
    end
    status = "No images loaded";
    if ~isempty(sources)
        status = string(numel(sources)) + " image(s)";
    end
    spec = struct("Files", files, "Status", status);
end

function text = sourceDescription(sources)
    if isempty(sources)
        text = "No images loaded";
        return;
    end
    folder = string(fileparts(sources(1).reference.originalPath));
    text = "Selected image files from " + folder;
end

function data = resultTableData(cacheResult, durableResult)
    if cacheResult.ok
        data = focus_stack.userInterface.resultTableData(cacheResult);
    elseif durableResult.ok
        data = focus_stack.userInterface.resultTableData(durableResult);
    else
        data = focus_stack.userInterface.initialResultTable();
    end
end

function lines = detailLines(state, hasSources, hasStack)
    result = state.session.cache.result;
    if ~result.ok
        result = state.project.results.lastRun;
    end
    if result.ok
        lines = focus_stack.userInterface.details(result, ...
            sourcePaths(state.project.inputs.sources), ...
            cellstr(state.project.results.registrationLines));
        if ~state.session.cache.result.ok
            lines{end + 1} = ...
                'Saved summary restored; rerun to rebuild image previews and exports.';
        end
        if strlength(state.project.results.resultManifestPath) > 0
            lines{end + 1} = "Last manifest: " + ...
                state.project.results.resultManifestPath;
        end
    elseif hasStack
        lines = {sprintf('Loaded images: %d', ...
            numel(state.project.inputs.sources)), ...
            'Run focus stack to compute the fused image and focus-depth map.'};
    elseif hasSources
        lines = {sprintf('Loaded images: %d', ...
            numel(state.project.inputs.sources)), ...
            'Load at least two images before running focus stack.'};
    else
        lines = {'Load a focus image folder or select image files to begin.'};
    end
    lines = cellstr(string(lines));
end

function [fused, map] = previewModels(images, result)
    fused = imageModel([], "Fused all-in-focus image");
    map = imageModel([], "Focus-depth index map");
    if result.ok
        fused.imageData = result.fused;
        map.imageData = focus_stack.userInterface.focusIndexRgb( ...
            result.focusIndex, result.inputCount);
    elseif ~isempty(images)
        fused.imageData = focus_stack.userInterface.previewImage(images{1});
        fused.title = "First source image";
    end
end

function model = imageModel(imageData, titleText)
    model = struct("imageData", imageData, "title", string(titleText));
end

function paths = sourcePaths(sources)
    paths = strings(numel(sources), 1);
    for k = 1:numel(sources)
        paths(k) = string(sources(k).reference.originalPath);
    end
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = dataSpec(value)
    spec = struct("Data", {value});
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end
