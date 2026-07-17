% Rebuild transient decoded images and full result caches from one validated
% Focus Stack project. Runtime V2 calls this after source relinking.
function session = createSession(project)
    images = loadImages(project.inputs.sources);
    session = struct( ...
        "workflow", struct("registrationLines", strings(0, 1)), ...
        "cache", struct( ...
            "images", {images}, ...
            "alignedImages", {{}}, ...
            "result", focus_stack.analysisRun.emptyResult()));
end
function images = loadImages(sources)
    images = {};
    if isempty(sources)
        return;
    end
    try
        images = focus_stack.sourceFiles.readImages( ...
            labkit.ui.runtime.sourcePaths(sources));
    catch
        % Missing portable references remain unloaded until sources are relinked.
    end
end
