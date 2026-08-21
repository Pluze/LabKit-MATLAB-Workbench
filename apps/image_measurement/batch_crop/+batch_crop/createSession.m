% Rebuild transient task paths and the first selected image.
function session = createSession(project, ~)
    currentIndex = double(~isempty(project.inputs.items));
    images = cell(numel(project.inputs.items), 1);
    paths = taskPaths(project.inputs.items, project.inputs.sources);
    if currentIndex > 0
        path = paths(currentIndex);
        if strlength(path) > 0
            loaded = batch_crop.sourceFiles.readItems(path);
            if ~isempty(loaded)
                images{currentIndex} = loaded(1).image;
            end
        end
    end
    session = struct( ...
        "selection", struct("currentIndex", currentIndex), ...
        "workflow", struct( ...
            "cropDefaultsInitialized", ~isempty(project.inputs.items), ...
            "scaleReferenceEditing", false), ...
        "view", struct("scaleBar", []), ...
        "cache", struct( ...
            "images", {images}, ...
            "paths", paths, ...
            "canvas", batch_crop.cropGeometry.emptyCanvasCache()));
end

function paths = taskPaths(tasks, sources)
paths = strings(numel(tasks), 1);
for k = 1:numel(tasks)
    sourceId = string(tasks(k).sourceId);
    match = find(string({sources.id}) == sourceId, 1);
    if isempty(match)
        continue
    end
    resolved = labkit.app.source.paths(sources(match));
    if ~isempty(resolved)
        paths(k) = resolved(1);
    end
end
end
