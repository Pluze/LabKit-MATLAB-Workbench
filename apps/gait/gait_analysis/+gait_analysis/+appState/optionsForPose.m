%OPTIONSFORPOSE Apply source-owned time, scale, and role facts to gait options.
% Expected caller: pose load action. Source metadata replaces defaults only
% when the source supplies an explicit usable value.
function options = optionsForPose(pose, options)
    defaults = gait_analysis.appState.defaultOptions();
    options.frameRate = defaults.frameRate;
    options.pixelsPerUnit = defaults.pixelsPerUnit;
    options.unitName = defaults.unitName;
    if isfield(pose, "frameRate") && isscalar(pose.frameRate) && ...
            isfinite(pose.frameRate) && pose.frameRate > 0
        options.frameRate = double(pose.frameRate);
    end
    if isfield(pose, "pixelsPerUnit") && isscalar(pose.pixelsPerUnit) && ...
            isfinite(pose.pixelsPerUnit) && pose.pixelsPerUnit > 0
        options.pixelsPerUnit = double(pose.pixelsPerUnit);
        options.unitName = string(pose.unitName);
    end
    roleFields = ["iliacPoint", "hipPoint", "kneePoint", ...
        "anklePoint", "footPoint"];
    roleCandidates = ["iliac", "hip", "knee", "ankle", "foot"];
    names = string(pose.pointNames(:));
    for k = 1:numel(roleFields)
        options.(roleFields(k)) = defaults.(roleFields(k));
        match = find(lower(names) == roleCandidates(k), 1);
        if isempty(match) && roleCandidates(k) == "iliac"
            match = find(lower(names) == "iliac_crest", 1);
        end
        if ~isempty(match)
            options.(roleFields(k)) = names(match);
        end
    end
end
