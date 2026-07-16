% Expected caller: the LabKit V2 runtime. Input is a validated project.
% Output owns ephemeral selection, logs, and only the selected decoded item.
function session = createSession(project)
    index = double(~isempty(project.inputs.sources));
    item = [];
    if index > 0
        item = loadSelected(project, index);
    end
    session = struct( ...
        "selection", struct("currentIndex", index), ...
        "workflow", struct("logLines", strings(0, 1)), ...
        "view", struct(), ...
        "cache", struct("currentItem", item));
end

function item = loadSelected(project, index)
    item = [];
    try
        source = project.inputs.sources(index);
        loaded = flir_thermal.sourceFiles.readImages( ...
            source.reference.originalPath);
        if ~isempty(loaded)
            annotation = annotationFor(project.annotations.items, source.id);
            item = flir_thermal.appState.applyAnnotation(loaded(1), annotation);
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
