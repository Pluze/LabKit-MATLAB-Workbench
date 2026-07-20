% Rebuild the selected transient decoded image from one validated FLIR
% project. App SDK runtime calls this after portable source relinking.
function session = createSession(project, context)
    index = double(~isempty(project.inputs.sources));
    item = [];
    if index > 0
        item = loadSelected(project, index, context);
    end
    session = struct( ...
        "selection", struct("currentIndex", index, ...
            "thermalSources", labkit.app.event.ListSelection()), ...
        "cache", struct("currentItem", item));
end

function item = loadSelected(project, index, context)
    item = [];
    source = project.inputs.sources(index);
    loaded = flir_thermal.sourceFiles.readImages( ...
        context.resolveSourcePaths(source), ...
        struct("SkipInvalid", false));
    if ~isempty(loaded)
        annotation = annotationFor(project.annotations.items, source.id);
        item = flir_thermal.thermalAnnotations.apply(loaded(1), annotation);
    end
end

function annotation = annotationFor(annotations, sourceId)
    annotation = [];
    if isempty(annotations)
        return;
    end
    index = find(string({annotations.sourceId}) == string(sourceId), 1);
    if ~isempty(index)
        annotation = annotations(index);
    end
end
