% App-owned implementation for batch_crop.sourceFiles.loadCurrent within the batch_crop product workflow.
function [applicationState, loaded] = loadCurrent( ...
        applicationState, callbackContext)
%LOADCURRENT Lazily decode the selected crop task through resolved paths.
loaded = false;
index = batch_crop.sourceFiles.currentIndex(applicationState);
if index < 1 || index > numel(applicationState.project.inputs.items)
    return
end
try
    if index <= numel(applicationState.session.cache.images) && ...
            ~isempty(applicationState.session.cache.images{index})
        loaded = true;
        return
    end
    sourceId = string(applicationState.project.inputs.items(index).sourceId);
    sources = applicationState.project.inputs.sources;
    match = find(string({sources.id}) == sourceId, 1);
    if isempty(match)
        return
    end
    paths = callbackContext.resolveSourcePaths(sources(match));
    if isempty(paths) || strlength(paths(1)) == 0
        return
    end
    loadedItems = batch_crop.sourceFiles.readItems(paths(1));
    if isempty(loadedItems)
        error("labkit_BatchImageCrop_app:ImageNotLoaded", ...
            "No image was loaded for crop task %d.", index);
    end
    applicationState.session.cache.images{index} = loadedItems(1).image;
    applicationState.session.cache.paths(index) = paths(1);
    loaded = true;
catch cause
    callbackContext.reportError("Could not load image", cause);
    callbackContext.log("error", "batch_crop.sourcefiles.loadcurrent.failed", ...
        "Could not load the selected crop task.");
end
end
