% App-owned implementation for image_enhance.workbench.present within the image_enhance product workflow.
function view = present(applicationState)
%PRESENT Build one complete Image Enhance workbench snapshot.
project = applicationState.project;
session = applicationState.session;
steps = image_enhance.analysisRun.activeSteps(applicationState);
hasImage = ~isempty(session.cache.item);
availability = ...
    image_enhance.imagePreview.presentationData.toolAvailability( ...
        applicationState, session.view.toolKind);
defaults = image_enhance.analysisRun.defaultStepValues( ...
    session.view.toolKind);
view = labkit.app.view.Snapshot();
view = view.value("imageStatus", sprintf( ...
    "Images: %d | current steps: %d", ...
    numel(project.inputs.sources), numel(steps)));
view = view.value("batchMode", project.parameters.batchMode);
view = view.value("batchModeStatus", modeStatus(project.parameters.batchMode));
view = view.value("toolKind", session.view.toolKind);
view = view.value("toolAmount", session.view.toolAmount);
view = view.limits("toolAmount", defaults.amountLimits);
view = view.value("toolSecondary", session.view.toolSecondary);
view = view.limits("toolSecondary", defaults.secondaryLimits);
view = view.value("toolStatus", toolStatus( ...
    applicationState, availability));
view = view.enabled("setWhiteRoi", availability.canSetWhiteRoi);
view = view.enabled("applyTool", availability.canApply);
view = view.enabled("undoHistory", ~isempty(steps));
view = view.enabled("resetHistory", ~isempty(steps));
view = view.tableData("historyTable", ...
    image_enhance.imagePreview.presentationData.historyTableData(steps), ...
    Columns=["#" "Step" "Settings"]);
view = view.value("historyStatus", ...
    sprintf("History steps: %d", numel(steps)));
view = view.tableData("metricsTable", metricData( ...
    session.cache.item, session.cache.previewResult, numel(steps)), ...
    Columns=["Metric" "Value"]);
view = view.value("outputFolder", project.parameters.outputFolder);
view = view.value("exportFormat", project.parameters.exportFormat);
view = view.enabled("exportImages", hasImage);
view = view.text("exportDetails", strjoin(string( ...
    detailLines(applicationState, steps)), newline));
view = view.value("preview", session.view.previewMode);
model = previewModel(applicationState);
view = view.renderPlot("preview", model, ...
    ViewRevision=image_enhance.imagePreview.viewportRevision( ...
        session.cache.sourceId, session.view.previewMode, ...
        model.imageData));
if roiInteractionVisible(applicationState)
    annotation = currentAnnotation(applicationState);
    view = view.rectangle("whiteRoi", ...
        annotation.whiteRoi .* session.cache.previewScale, ...
        ImageSize=size(session.cache.previewSource), Enabled=true);
else
    view = view.rectangle("whiteRoi", [0 0 0 0], ...
        ImageSize=[], Enabled=false);
end
end

function text = modeStatus(batchMode)
if batchMode
    text = "Batch mode: all images share the same parameters and history.";
else
    text = "Per-image mode: each image keeps its own parameters and history.";
end
end

function text = toolStatus(applicationState, availability)
step = image_enhance.analysisRun.makeStep( ...
    applicationState.session.view.toolKind, ...
    applicationState.session.view.toolAmount, ...
    applicationState.session.view.toolSecondary, 0);
if availability.isWhiteRoi
    text = availability.status;
elseif applicationState.session.workflow.pendingDirty
    text = "Previewing: " + string(step.label) + ...
        " | " + string(availability.status);
else
    text = "Ready: " + string(step.label) + ...
        " | " + string(availability.status);
end
end

function data = metricData(item, previewResult, stepCount)
data = image_enhance.imagePreview.presentationData.resultTableData( ...
    item, previewResult, stepCount);
end

function lines = detailLines(applicationState, steps)
sources = applicationState.project.inputs.sources;
item = applicationState.session.cache.item;
if isempty(sources) || isempty(item)
    lines = {"Load one or more images to begin enhancement."};
    return;
end
lines = { ...
    sprintf("Selected: %s", char(item.name)), ...
    sprintf("Images registered: %d", numel(sources)), ...
    sprintf("History steps: %d", numel(steps))};
if ~isempty(steps)
    lines{end + 1} = sprintf("Last step: %s", ...
        char(image_enhance.analysisRun.describeStep(steps(end))));
end
manifest = applicationState.project.results.resultManifestPath;
if strlength(manifest) > 0
    lines{end + 1} = "Last manifest: " + manifest;
end
end

function model = previewModel(applicationState)
session = applicationState.session;
original = session.cache.previewSource;
enhanced = session.cache.previewResult;
switch session.view.previewMode
    case "Original"
        imageData = original;
        titleText = "Original Preview";
    case "Before | After"
        imageData = ...
            image_enhance.imagePreview.presentationData.beforeAfterImage( ...
                original, enhanced);
        titleText = "Before | After";
    otherwise
        imageData = enhanced;
        titleText = "Enhanced Preview";
end
roi = [];
if ~isempty(original) && session.view.previewMode ~= "Before | After" && ...
        ~session.view.roiEditing
    annotation = currentAnnotation(applicationState);
    candidate = double(annotation.whiteRoi);
    if numel(candidate) == 4 && all(isfinite(candidate)) && ...
            all(candidate(3:4) > 0)
        roi = candidate .* session.cache.previewScale;
    end
end
model = struct("imageData", imageData, ...
    "title", titleText, "whiteRoi", roi);
end

function annotation = currentAnnotation(applicationState)
annotation = image_enhance.enhancementAnnotations.empty();
index = applicationState.session.selection.currentIndex;
sources = applicationState.project.inputs.sources;
if index < 1 || index > numel(sources)
    return;
end
annotation = image_enhance.sourceLibrary.annotationForSource( ...
    applicationState.project.annotations.items, sources(index).id);
end

function value = roiInteractionVisible(applicationState)
index = applicationState.session.selection.currentIndex;
value = applicationState.session.view.roiEditing && ...
    applicationState.session.view.previewMode ~= "Before | After" && ...
    ~isempty(applicationState.session.cache.previewSource) && ...
    index >= 1 && ...
    index <= numel(applicationState.project.inputs.sources);
end
