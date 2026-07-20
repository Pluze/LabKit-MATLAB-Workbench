%CREATESESSION Rebuild transient DIC images and editor workflow state.
% Expected caller: App SDK through dic_preprocess.definition. Input is a
% validated project; decoded and replayed images remain outside persistence.
function session = createSession(project, context)
    referencePath = rolePath(project.inputs.sources, ...
        "referenceImage", context);
    movingPath = rolePath(project.inputs.sources, ...
        "movingImage", context);
    [referenceImage, movingImage] = ...
        dic_preprocess.sourceFiles.loadProjectImages( ...
            referencePath, movingPath);
    cache = dic_preprocess.analysisRun.replayEditSteps( ...
        referenceImage, movingImage, project.annotations.editSteps);
    session = struct( ...
        "workflow", struct( ...
            "mode", "idle", ...
            "details", {{'Alignment and crop details will appear here.'}}), ...
        "cache", cache);
end

function filepath = rolePath(sources, role, context)
filepath = "";
if isempty(sources)
    return
end
match = find(string({sources.role}) == role, 1);
if isempty(match)
    return
end
paths = context.resolveSourcePaths(sources(match));
if ~isempty(paths)
    filepath = paths(1);
end
end
