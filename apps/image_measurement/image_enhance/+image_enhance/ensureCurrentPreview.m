% Expected caller: Image Enhance lifecycle and actions. Inputs are canonical
% state and runtime services. Output lazily owns only the selected decoded
% image and its downsampled preview; failures are logged and reported.
function state = ensureCurrentPreview(state, services)
    sources = state.project.inputs.sources;
    index = state.session.selection.currentIndex;
    if isempty(sources) || index < 1 || index > numel(sources)
        state.session.cache = emptyCache();
        return;
    end
    source = sources(index);
    if state.session.cache.sourceId == string(source.id) && ...
            ~isempty(state.session.cache.item)
        return;
    end
    state.session.cache = emptyCache();
    try
        loaded = image_enhance.sourceFiles.readImages( ...
            source.reference.originalPath);
        if isempty(loaded)
            return;
        end
        [preview, scale] = image_enhance.userInterface.previewImage( ...
            loaded(1).image);
        state.session.cache.sourceId = string(source.id);
        state.session.cache.item = loaded(1);
        state.session.cache.previewSource = preview;
        state.session.cache.previewScale = scale;
    catch ME
        services.diagnostics.report("Could not load image", ME);
        services.dialogs.alert(ME.message, "Could not load image");
        state = services.workflow.log(state, ...
            "Could not load selected image: " + string(ME.message));
    end
end

function cache = emptyCache()
    cache = struct("sourceId", "", "item", [], ...
        "previewSource", [], "previewScale", 1, ...
        "previewResult", [], "previewResultKey", "");
end
