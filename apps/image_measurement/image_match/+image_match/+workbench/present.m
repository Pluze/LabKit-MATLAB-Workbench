% App-owned implementation for image_match.workbench.present within the image_match product workflow.
function view = present(applicationState)
%PRESENT Build one complete Image Match workbench snapshot.
project = applicationState.project;
session = applicationState.session;
steps = project.annotations.steps;
ready = ~isempty(session.cache.referenceItem) && ...
    ~isempty(session.cache.currentItem);
view = labkit.app.view.Snapshot();
view = view.value("imageStatus", sprintf( ...
    "Images: %d | match steps: %d", ...
    numel(project.inputs.sources), numel(steps)));
view = view.value("matchMethod", project.parameters.matchMethod);
view = view.value("matchStrength", project.parameters.matchStrength);
view = view.value("toneStrength", project.parameters.toneStrength);
view = view.value("colorStrength", project.parameters.colorStrength);
view = view.text("matchFlow", strjoin(string( ...
    image_match.imagePreview.presentationData.matchFlowLines( ...
        project.parameters.matchMethod)), newline));
view = view.enabled("applyMatch", ready);
view = view.enabled("undoHistory", ~isempty(steps));
view = view.enabled("resetHistory", ~isempty(steps));
view = view.value("historyStatus", ...
    sprintf("History steps: %d", numel(steps)));
view = view.value("outputFolder", project.parameters.outputFolder);
view = view.value("exportFormat", project.parameters.exportFormat);
view = view.enabled("exportImages", ready);
view = view.text("exportDetails", strjoin(string( ...
    detailLines(applicationState)), newline));
view = view.value("preview", session.view.previewMode);
sourceId = "";
index = session.selection.currentIndex;
if index >= 1 && index <= numel(project.inputs.sources)
    sourceId = string(project.inputs.sources(index).id);
end
view = view.include(image_match.imagePreview.present( ...
    steps, session.cache.currentItem, ...
    session.cache.previewSource, session.cache.previewResult, ...
    session.view.previewMode, sourceId));
end

function lines = detailLines(applicationState)
project = applicationState.project;
cache = applicationState.session.cache;
if isempty(project.inputs.sources)
    lines = {"Load a reference and one or more source images."};
    return;
end
referenceName = "-";
if ~isempty(cache.referenceItem)
    referenceName = string(cache.referenceItem.name);
end
selectedName = "-";
if ~isempty(cache.currentItem)
    selectedName = string(cache.currentItem.name);
end
lines = { ...
    "Selected: " + selectedName, ...
    "Source images: " + string(numel(project.inputs.sources)), ...
    "Reference: " + referenceName, ...
    "History steps: " + string(numel(project.annotations.steps))};
if strlength(project.results.resultManifestPath) > 0
    lines{end + 1} = ...
        "Last manifest: " + project.results.resultManifestPath;
end
end
