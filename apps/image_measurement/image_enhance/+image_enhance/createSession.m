% Rebuild transient selection, draft controls, and the selected preview from
% one validated Image Enhance project after Runtime V2 resolves sources.
function session = createSession(project, context)
    index = double(~isempty(project.inputs.sources));
    kinds = image_enhance.imagePreview.presentationData.toolKinds();
    defaults = image_enhance.analysisRun.defaultStepValues(kinds{1});
    cache = emptyCache();
    if index > 0
        cache = loadSelectedCache(project.inputs.sources(index), cache, context);
        cache = rebuildSelectedResult(project, index, cache);
    end
    session = struct( ...
        "selection", struct("currentIndex", index, ...
            "sourceImages", labkit.app.event.ListSelection()), ...
        "workflow", struct("pendingDirty", false), ...
        "view", struct("previewMode", "Enhanced", ...
            "toolKind", string(kinds{1}), ...
            "toolAmount", defaults.amount, ...
            "toolSecondary", defaults.secondary, ...
            "roiEditing", false), ...
        "cache", cache);
end

function cache = rebuildSelectedResult(project, index, cache)
    if isempty(cache.previewSource)
        return;
    end
    if project.parameters.batchMode
        steps = project.annotations.sharedSteps;
        whiteRoi = [];
    else
        annotation = image_enhance.sourceLibrary.annotationForSource( ...
            project.annotations.items, project.inputs.sources(index).id);
        steps = annotation.steps;
        whiteRoi = annotation.whiteRoi;
    end
    cache.previewResult = image_enhance.analysisRun.previewResult( ...
        cache.previewSource, steps, ...
        whiteRoi, cache.previewScale);
    cache.previewResultKey = "restored";
end

function cache = loadSelectedCache(source, cache, context)
    loaded = image_enhance.sourceFiles.readImages( ...
        context.resolveSourcePaths(source));
    if isempty(loaded)
        return;
    end
    [preview, scale] = image_enhance.imagePreview.presentationData.previewImage( ...
        loaded(1).image);
    cache.sourceId = string(source.id);
    cache.item = loaded(1);
    cache.previewSource = preview;
    cache.previewScale = scale;
end

function cache = emptyCache()
    cache = struct("sourceId", "", "item", [], ...
        "previewSource", [], "previewScale", 1, ...
        "previewResult", [], "previewResultKey", "");
end
