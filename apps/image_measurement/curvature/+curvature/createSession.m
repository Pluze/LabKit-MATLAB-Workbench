% Rebuild the decoded image and transient interaction state from one validated
% Curvature project. App SDK runtime calls this after source relinking.
function session = createSession(project, context)
    paths = strings(0, 1);
    if ~isempty(project.inputs.sources)
        paths = context.resolveSourcePaths(project.inputs.sources);
    end
    imagePath = "";
    if ~isempty(paths), imagePath = paths(1); end
    imageData = [];
    if strlength(imagePath) > 0 && isfile(imagePath)
        imageData = imread(imagePath);
    end
    session = struct( ...
        "workflow", struct( ...
            "editMode", "none", ...
            "statusMessage", initialStatus(imageData)), ...
        "view", struct("scaleBar", []), ...
        "cache", struct( ...
            "imagePath", imagePath, ...
            "image", imageData, ...
            "fitFingerprint", "", ...
            "lengthFingerprint", ""));
end

function message = initialStatus(imageData)
    if isempty(imageData)
        message = "Open an image to trace a curve.";
    else
        message = "Project image restored.";
    end
end
