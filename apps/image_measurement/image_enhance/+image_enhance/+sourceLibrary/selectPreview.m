% App-owned implementation for image_enhance.sourceLibrary.selectPreview within the image_enhance product workflow.
function applicationState = selectPreview( ...
        applicationState, listSelection, callbackContext)
%SELECTPREVIEW Lazily decode and present the selected portable source.
applicationState.project.annotations.items = reconcileAnnotations( ...
    applicationState.project.annotations.items, ...
    applicationState.project.inputs.sources);
applicationState = invalidateChangedSourceExport(applicationState);
if isempty(listSelection.Indices)
    applicationState.session.selection.currentIndex = 0;
    applicationState.session.cache = emptySelectedCache( ...
        applicationState.session.cache);
    return;
end
index = listSelection.Indices(1);
sources = applicationState.project.inputs.sources;
if index > numel(sources)
    return;
end
source = sources(index);
try
    paths = callbackContext.resolveSourcePaths(source);
    items = image_enhance.sourceFiles.readImages(paths);
catch ME
    callbackContext.reportError("Load image preview", ME);
    callbackContext.alert(ME.message, "Could not load image preview");
    return;
end
if isempty(items)
    return;
end
if strlength( ...
        applicationState.project.parameters.outputFolder) == 0
    applicationState.project.parameters.outputFolder = string(fullfile( ...
        fileparts(paths(1)), "image_enhance"));
end
[preview, scale] = ...
    image_enhance.imagePreview.presentationData.previewImage( ...
        items(1).image);
applicationState.session.selection.currentIndex = index;
applicationState.session.workflow.pendingDirty = false;
applicationState.session.view.roiEditing = false;
applicationState.session.cache.sourceId = string(source.id);
applicationState.session.cache.item = items(1);
applicationState.session.cache.previewSource = preview;
applicationState.session.cache.previewScale = scale;
applicationState.session.cache.previewResult = [];
applicationState.session.cache.previewResultKey = "";
applicationState = ...
    image_enhance.enhancementPipeline.rebuildPreview(applicationState);
end

function items = reconcileAnnotations(items, sources)
current = items;
items = repmat( ...
    image_enhance.enhancementAnnotations.empty(), numel(sources), 1);
for index = 1:numel(sources)
    items(index) = image_enhance.sourceLibrary.annotationForSource( ...
        current, sources(index).id);
end
end

function applicationState = invalidateChangedSourceExport(applicationState)
lastExport = applicationState.project.results.lastExport;
if isempty(lastExport) || ~isfield(lastExport, "sourceIds")
    return;
end
currentIds = string({applicationState.project.inputs.sources.id});
if ~isequal(currentIds(:), string(lastExport.sourceIds(:)))
    applicationState = ...
        image_enhance.enhancementPipeline.invalidateResults(applicationState);
end
end

function cache = emptySelectedCache(cache)
cache.sourceId = "";
cache.item = [];
cache.previewSource = [];
cache.previewScale = 1;
cache.previewResult = [];
cache.previewResultKey = "";
end
