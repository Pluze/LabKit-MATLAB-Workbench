% Rebuild transient decoded images and preview caches from one validated
% Image Match project. App SDK runtime calls this after source relinking.
function session = createSession(project, context)
    index = double(~isempty(project.inputs.sources));
    cache = emptyCache();
    if ~isempty(project.inputs.reference)
        cache.referenceItem = loadItem(project.inputs.reference, context);
    end
    if index > 0
        cache.currentItem = loadItem(project.inputs.sources(1), context);
    end
    cache = rebuildResult(project, cache);
    session = struct( ...
        "selection", struct( ...
            "referenceImage", labkit.app.event.ListSelection(), ...
            "sourceImages", labkit.app.event.ListSelection(), ...
            "currentIndex", index), ...
        "workflow", struct("pendingDirty", false), ...
        "view", struct("previewMode", "Matched"), ...
        "cache", cache);
end

function item = loadItem(source, context)
    item = [];
    loaded = image_match.sourceFiles.readImages( ...
        context.resolveSourcePaths(source));
    if ~isempty(loaded)
        item = loaded(1);
    end
end

function cache = rebuildResult(project, cache)
    if isempty(cache.currentItem) || isempty(cache.referenceItem)
        return;
    end
    cache.previewSource = image_match.imagePreview.presentationData.previewImage( ...
        cache.currentItem.image);
    cache.previewReference = image_match.imagePreview.presentationData.previewImage( ...
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
