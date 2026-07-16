% Expected caller: Runtime V2. Input is a validated curvature project with a
% resolved image source. Output owns the decoded image, edit mode, transient
% scale-bar geometry, fingerprints, and workflow log.
function session = createSession(project)
    imagePath = sourcePath(project.inputs.sources);
    imageData = [];
    if strlength(imagePath) > 0 && isfile(imagePath)
        imageData = imread(imagePath);
    end
    session = struct( ...
        "selection", struct(), ...
        "workflow", struct( ...
            "editMode", "none", ...
            "statusMessage", initialStatus(imageData), ...
            "logLines", strings(0, 1)), ...
        "view", struct("scaleBar", []), ...
        "cache", struct( ...
            "imagePath", imagePath, ...
            "image", imageData, ...
            "fitFingerprint", "", ...
            "lengthFingerprint", ""));
end

function pathValue = sourcePath(sources)
    pathValue = "";
    if ~isempty(sources)
        pathValue = string(sources(1).reference.originalPath);
    end
end

function message = initialStatus(imageData)
    if isempty(imageData)
        message = "Open an image to trace a curve.";
    else
        message = "Project image restored.";
    end
end
