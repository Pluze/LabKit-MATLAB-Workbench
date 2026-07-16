% Expected caller: the LabKit V2 runtime. Input is a validated project.
% Output owns decoded images, aligned images, full result matrices, and logs.
function session = createSession(project)
    images = loadImages(project.inputs.sources);
    session = struct( ...
        "selection", struct(), ...
        "workflow", struct("logLines", strings(0, 1), ...
            "registrationLines", strings(0, 1)), ...
        "view", struct(), ...
        "cache", struct( ...
            "images", {images}, ...
            "alignedImages", {{}}, ...
            "result", focus_stack.appState.emptyResult()));
end

function images = loadImages(sources)
    images = {};
    if isempty(sources)
        return;
    end
    try
        images = focus_stack.sourceFiles.readImages(sourcePaths(sources));
    catch
        % Missing portable references remain unloaded until sources are relinked.
    end
end

function paths = sourcePaths(sources)
    paths = strings(numel(sources), 1);
    for k = 1:numel(sources)
        paths(k) = string(sources(k).reference.originalPath);
    end
end
