% Rebuild the selected transient decoded image from one validated FLIR
% project. Runtime V2 calls this after portable source relinking.
function session = createSession(project)
    index = double(~isempty(project.inputs.sources));
    item = [];
    if index > 0
        item = loadSelected(project, index);
    end
    session = struct( ...
        "selection", struct("currentIndex", index), ...
        "cache", struct("currentItem", item));
end

function item = loadSelected(project, index)
    item = [];
    try
        source = project.inputs.sources(index);
        loaded = flir_thermal.sourceFiles.readImages( ...
            labkit.ui.runtime.sourcePaths(source));
        if ~isempty(loaded)
            annotation = annotationFor(project.annotations.items, source.id);
            item = flir_thermal.thermalAnnotations.apply(loaded(1), annotation);
        end
    catch
        % Missing portable references stay unloaded until the user relinks.
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
