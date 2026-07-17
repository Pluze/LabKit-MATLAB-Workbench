% Expected caller: the LabKit V2 runtime. Input is canonical Image Enhance
% state. Output is a deterministic control, preview, and controlled ROI view.
function view = presentWorkbench(state)
    sources = state.project.inputs.sources;
    index = state.session.selection.currentIndex;
    steps = image_enhance.analysisRun.activeSteps(state);
    hasImage = ~isempty(state.session.cache.item);
    availability = image_enhance.userInterface.toolAvailability( ...
        state, state.session.view.toolKind);
    defaults = image_enhance.analysisRun.defaultStepValues( ...
        state.session.view.toolKind);

    view = struct();
    view.controls.sourceImages = sourceSpec(sources, index);
    view.controls.imageStatus = valueSpec(sprintf( ...
        'Images: %d | current steps: %d', numel(sources), numel(steps)));
    view.controls.batchMode = valueSpec(state.project.parameters.batchMode);
    view.controls.batchModeStatus = valueSpec(modeStatus(state));
    view.controls.toolKind = valueSpec(state.session.view.toolKind);
    view.controls.toolAmount = struct("Value", state.session.view.toolAmount, ...
        "Limits", defaults.amountLimits);
    view.controls.toolSecondary = struct( ...
        "Value", state.session.view.toolSecondary, ...
        "Limits", defaults.secondaryLimits);
    view.controls.toolStatus = valueSpec(toolStatus(state, availability));
    view.controls.setWhiteRoi = enabledSpec(availability.canSetWhiteRoi);
    view.controls.applyTool = enabledSpec(availability.canApply);
    view.controls.undoHistory = enabledSpec(~isempty(steps));
    view.controls.resetHistory = enabledSpec(~isempty(steps));
    view.controls.historyTable = dataSpec( ...
        image_enhance.userInterface.historyTableData(steps));
    view.controls.historyStatus = valueSpec(sprintf( ...
        'History steps: %d', numel(steps)));
    view.controls.metricsTable = dataSpec(metricData(state, steps));
    view.controls.outputFolder = valueSpec( ...
        state.project.parameters.outputFolder);
    view.controls.exportFormat = valueSpec( ...
        state.project.parameters.exportFormat);
    view.controls.exportImages = enabledSpec(hasImage);
    view.controls.exportDetails = valueSpec(detailLines(state, steps));
    view.controls.preview = valueSpec(state.session.view.previewMode);

    model = previewModel(state);
    view.previews.preview = struct("Renderer", "imagePreview", "Model", model);
    if roiInteractionVisible(state)
        annotation = state.project.annotations.items(index);
        view.interactions.whiteRoi = struct( ...
            "Kind", "rectangle", ...
            "Targets", "preview", ...
            "Value", annotation.whiteRoi .* state.session.cache.previewScale, ...
            "Event", "whiteRoiEdited", ...
            "ImageSize", size(state.session.cache.previewSource), ...
            "ChangePolicy", "commit", ...
            "Options", struct("color", [1 1 1], "lineWidth", 1.5));
    end
end

function spec = sourceSpec(sources, index)
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
    if isempty(sources)
        status = "No images loaded";
    else
        status = sprintf('%d image(s)', numel(sources));
    end
    spec = struct();
    spec.Files = files;
    spec.Selection = selection;
    spec.Status = status;
end

function text = modeStatus(state)
    if state.project.parameters.batchMode
        text = "Batch mode: all images share the same parameters and history.";
    else
        text = "Per-image mode: each image keeps its own parameters and history.";
    end
end

function text = toolStatus(state, availability)
    if availability.isWhiteRoi
        text = availability.status;
    elseif state.session.workflow.pendingDirty
        text = "Previewing: " + string(currentStep(state).label) + ...
            " | " + string(availability.status);
    else
        text = "Ready: " + string(currentStep(state).label) + ...
            " | " + string(availability.status);
    end
end

function step = currentStep(state)
    step = image_enhance.analysisRun.makeStep( ...
        state.session.view.toolKind, state.session.view.toolAmount, ...
        state.session.view.toolSecondary, 0);
end

function data = metricData(state, steps)
    if isempty(state.session.cache.item) || ...
            isempty(state.session.cache.previewResult)
        data = image_enhance.userInterface.resultTableData([], [], 0);
        return;
    end
    data = image_enhance.userInterface.resultTableData( ...
        state.session.cache.item, state.session.cache.previewResult, numel(steps));
end

function lines = detailLines(state, steps)
    sources = state.project.inputs.sources;
    index = state.session.selection.currentIndex;
    if isempty(sources) || index < 1 || index > numel(sources)
        lines = {'Load one or more images to begin enhancement.'};
        return;
    end
    path = labkit.ui.runtime.sourcePaths(sources(index));
    [~, name, extension] = fileparts(path);
    lines = {sprintf('Selected: %s', char(string(name) + string(extension))), ...
        sprintf('Images registered: %d', numel(sources)), ...
        sprintf('History steps: %d', numel(steps))};
    if ~isempty(steps)
        lines{end + 1} = sprintf('Last step: %s', ...
            char(image_enhance.analysisRun.describeStep(steps(end))));
    end
    if strlength(state.project.results.resultManifestPath) > 0
        lines{end + 1} = sprintf('Last manifest: %s', ...
            char(state.project.results.resultManifestPath));
    elseif ~isempty(state.project.results.lastExport) && ...
            isfield(state.project.results.lastExport, 'manifestPath')
        lines{end + 1} = sprintf('Last manifest: %s', ...
            char(state.project.results.lastExport.manifestPath));
    end
end

function model = previewModel(state)
    original = state.session.cache.previewSource;
    enhanced = state.session.cache.previewResult;
    mode = state.session.view.previewMode;
    switch mode
        case "Original"
            imageData = original;
            titleText = "Original Preview";
        case "Before | After"
            imageData = image_enhance.userInterface.beforeAfterImage( ...
                original, enhanced);
            titleText = "Before | After";
        otherwise
            imageData = enhanced;
            titleText = "Enhanced Preview";
    end
    roi = [];
    index = state.session.selection.currentIndex;
    if ~isempty(original) && mode ~= "Before | After" && ...
            index >= 1 && index <= numel(state.project.annotations.items)
        candidate = state.project.annotations.items(index).whiteRoi;
        if numel(candidate) == 4 && all(isfinite(candidate)) && ...
                all(candidate(3:4) > 0) && ~state.session.view.roiEditing
            roi = candidate .* state.session.cache.previewScale;
        end
    end
    model = struct("imageData", imageData, "title", titleText, ...
        "whiteRoi", roi);
end

function tf = roiInteractionVisible(state)
    index = state.session.selection.currentIndex;
    tf = state.session.view.roiEditing && ...
        state.session.view.previewMode ~= "Before | After" && ...
        ~isempty(state.session.cache.previewSource) && ...
        index >= 1 && index <= numel(state.project.annotations.items);
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
