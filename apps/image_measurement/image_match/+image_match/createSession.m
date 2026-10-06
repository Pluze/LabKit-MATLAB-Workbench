% Rebuild transient decoded images and preview caches from one validated
% Image Match project. App SDK runtime calls this after source relinking.
function session = createSession(project, ~)
    index = double(~isempty(project.inputs.sources));
    cache = emptyCache();
    if ~isempty(project.inputs.reference)
        cache.referenceItem = loadItem(project.inputs.reference);
    end
    if index > 0
        cache.currentItem = loadItem(project.inputs.sources(1));
    end
    cache = image_match.matchPipeline.refreshPreview( ...
        cache, project.annotations.steps);
    session = struct( ...
        "selection", struct( ...
            "referenceImage", labkit.app.event.ListSelection(), ...
            "sourceImages", labkit.app.event.ListSelection(), ...
            "currentIndex", index), ...
        "workflow", struct("pendingDirty", false), ...
        "view", struct("previewMode", "Matched"), ...
        "cache", cache);
end

function item = loadItem(source)
    item = [];
    loaded = image_match.sourceFiles.readImages( ...
        labkit.app.source.paths(source));
    if ~isempty(loaded)
        item = loaded(1);
    end
end

function cache = emptyCache()
    cache = struct("currentItem", [], "referenceItem", [], ...
        "previewSource", [], "previewReference", [], ...
        "previewResult", []);
end
