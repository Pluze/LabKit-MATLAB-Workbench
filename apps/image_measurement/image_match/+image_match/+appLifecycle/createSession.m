% Expected caller: the LabKit V2 runtime. Input is a validated project.
% Output owns ephemeral selection, pending preview state, logs, and decoded
% reference/current-source caches only.
function session = createSession(project)
    sourceIndices = find(string({project.inputs.sources.role}) == "source-image");
    index = double(~isempty(sourceIndices));
    cache = emptyCache();
    referenceIndex = find(string({project.inputs.sources.role}) == ...
        "reference-image", 1);
    if ~isempty(referenceIndex)
        cache.referenceItem = loadItem(project.inputs.sources(referenceIndex));
    end
    if index > 0
        cache.currentItem = loadItem(project.inputs.sources(sourceIndices(1)));
    end
    cache = rebuildResult(project, cache);
    session = struct( ...
        "selection", struct("currentIndex", index), ...
        "workflow", struct("logLines", strings(0, 1), ...
            "pendingDirty", false), ...
        "view", struct("previewMode", "Matched"), ...
        "cache", cache);
end

function item = loadItem(source)
    item = [];
    try
        loaded = image_match.sourceFiles.readImages( ...
            source.reference.originalPath);
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
