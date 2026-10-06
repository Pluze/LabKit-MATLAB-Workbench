% Decode selected focal planes and start with an empty fusion result.
function session = createSession(project, ~)
    [images, sourcePaths] = loadImages(project.inputs.sources);
    session = struct( ...
        "selection", struct("sourceImages", labkit.app.event.ListSelection()), ...
        "cache", struct( ...
            "images", {images}, ...
            "sourcePaths", sourcePaths, ...
            "plotViewRevision", 0, ...
            "result", focus_stack.analysisRun.emptyResult()));
end
function [images, paths] = loadImages(sources)
    images = {};
    paths = strings(0, 1);
    if isempty(sources)
        return;
    end
    paths = labkit.app.source.paths(sources);
    images = focus_stack.sourceFiles.readImages(paths);
end
