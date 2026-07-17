% Rebuild transient decoded images and preview caches from one validated
% Image Match project. Runtime V2 calls this after source relinking.
function session = createSession(project)
    sourceIndices = find(string({project.inputs.sources.role}) == "source-image");
    index = double(~isempty(sourceIndices));
    cache = emptyCache();
    referenceIndex = find(string({project.inputs.sources.role}) == ...
        "reference-image", 1);
    if ~isempty(referenceIndex)
        cache.referenceItem = loadItem( ...
            project.inputs.sources(referenceIndex));
    end
    if index > 0
        cache.currentItem = loadItem(project.inputs.sources(sourceIndices(1)));
    end
    cache = rebuildResult(project, cache);
    session = struct( ...
        "selection", struct("currentIndex", index), ...
        "workflow", struct("pendingDirty", false), ...
        "view", struct("previewMode", "Matched"), ...
        "cache", cache);
end

function item = loadItem(source)
    item = [];
    try
        loaded = image_match.sourceFiles.readImages( ...
            labkit.ui.runtime.sourcePaths(source));
        if ~isempty(loaded)
            item = loaded(1);
        end
    catch
        % Missing portable references remain empty until the user relinks.
    end
end

function cache = rebuildResult(project, cache)
    if isempty(cache.currentItem) || isempty(cache.referenceItem)
        return;
    end
    cache.previewSource = image_match.userInterface.previewImage( ...
        cache.currentItem.image);
    cache.previewReference = image_match.userInterface.previewImage( ...
        cache.referenceItem.image);
    processed = image_match.analysisRun.applyPipeline( ...
        {cache.previewSource}, project.annotations.steps, ...
        cache.previewReference);
    cache.previewResult = processed{1};
end

function cache = emptyCache()
    cache = struct("currentItem", [], "referenceItem", [], ...
        "previewSource", [], "previewReference", [], ...
        "previewResult", [], "previewResultKey", "");
end
