% Rebuild transient selection, draft controls, and the selected preview from
% one validated Image Enhance project after Runtime V2 resolves sources.
function session = createSession(project)
    index = double(~isempty(project.inputs.sources));
    kinds = image_enhance.userInterface.toolKinds();
    defaults = image_enhance.analysisRun.defaultStepValues(kinds{1});
    cache = emptyCache();
    if index > 0
        cache = loadSelectedCache(project.inputs.sources(index), cache);
        cache = rebuildSelectedResult(project, index, cache);
    end
    session = struct( ...
        "selection", struct("currentIndex", index), ...
        "workflow", struct("logLines", strings(0, 1), ...
            "pendingDirty", false), ...
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
    else
        steps = project.annotations.items(index).steps;
    end
    cache.previewResult = image_enhance.analysisRun.previewResult( ...
        cache.previewSource, steps, ...
        project.annotations.items(index).whiteRoi, cache.previewScale);
    cache.previewResultKey = "restored";
end

function cache = loadSelectedCache(source, cache)
    try
        loaded = image_enhance.sourceFiles.readImages( ...
            labkit.ui.runtime.sourcePaths(source));
        if isempty(loaded)
            return;
        end
        [preview, scale] = image_enhance.userInterface.previewImage( ...
            loaded(1).image);
        cache.sourceId = string(source.id);
        cache.item = loaded(1);
        cache.previewSource = preview;
        cache.previewScale = scale;
    catch
        % The runtime presents an empty cache when a source needs relinking.
    end
end

function cache = emptyCache()
    cache = struct("sourceId", "", "item", [], ...
        "previewSource", [], "previewScale", 1, ...
        "previewResult", [], "previewResultKey", "");
end
