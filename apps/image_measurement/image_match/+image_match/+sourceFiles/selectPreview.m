% App-owned implementation for image_match.sourceFiles.selectPreview within the image_match product workflow.
function applicationState = selectPreview( ...
        applicationState, listSelection, callbackContext)
%SELECTPREVIEW Lazily load and preview the selected source image.
sources = applicationState.project.inputs.sources;
applicationState = invalidateChangedSources(applicationState);
if isempty(listSelection.Indices)
    if isempty(sources)
        applicationState.project.annotations.steps = repmat( ...
            image_match.analysisRun.emptyStep(), 0, 1);
        applicationState.session.selection.currentIndex = 0;
        applicationState.session.cache.currentItem = [];
        applicationState.session.cache.previewSource = [];
        applicationState.session.cache.previewResult = [];
        applicationState = ...
            image_match.matchPipeline.invalidateResults(applicationState);
    end
    return;
end
index = listSelection.Indices(1);
if index > numel(sources)
    return;
end
try
    paths = callbackContext.resolveSourcePaths(sources(index));
    items = image_match.sourceFiles.readImages(paths);
catch ME
    callbackContext.log("error", "image_match.sourcefiles.selectpreview.exception", "Load image-match preview", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not load source image");
    return;
end
if isempty(items)
    return;
end
if strlength( ...
        applicationState.project.parameters.outputFolder) == 0
    applicationState.project.parameters.outputFolder = string(fullfile( ...
        fileparts(paths(1)), "image_match"));
end
applicationState.session.selection.currentIndex = index;
applicationState.session.workflow.pendingDirty = false;
applicationState.session.cache.currentItem = items(1);
applicationState = ...
    image_match.matchPipeline.rebuildPreview(applicationState);
end

function applicationState = invalidateChangedSources(applicationState)
lastExport = applicationState.project.results.lastExport;
if isempty(lastExport) || ~isfield(lastExport, "sourceIds")
    return;
end
ids = string({applicationState.project.inputs.sources.id});
if ~isequal(ids(:), string(lastExport.sourceIds(:)))
    applicationState = ...
        image_match.matchPipeline.invalidateResults(applicationState);
end
end
