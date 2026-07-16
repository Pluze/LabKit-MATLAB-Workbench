% Expected caller: Runtime V2 loading an earlier Gait project. The scientific
% result is invalidated because version 2 changes step boundaries and names.
function project = migrateProjectV1ToV2(project)
    renames = { ...
        'minStepIntervalSeconds', 'minLiftOffIntervalSeconds'; ...
        'minStepFrames', 'minSwingFrames'; ...
        'maxStepFrames', 'maxSwingFrames'; ...
        'minStride', 'minStepLength'; ...
        'maxBodyDrift', 'maxHipTranslation'};
    for k = 1:size(renames, 1)
        oldName = renames{k, 1};
        newName = renames{k, 2};
        if isfield(project.parameters, oldName) && ...
                ~isfield(project.parameters, newName)
            project.parameters.(newName) = project.parameters.(oldName);
        end
        if isfield(project.parameters, oldName)
            project.parameters = rmfield(project.parameters, oldName);
        end
    end
    defaults = gait_analysis.appState.defaultOptions();
    names = string(fieldnames(defaults));
    for k = 1:numel(names)
        name = char(names(k));
        if ~isfield(project.parameters, name)
            project.parameters.(name) = defaults.(name);
        end
    end
    project.results.analysis = gait_analysis.appState.emptyResult();
    project.results.lastExport = [];
end
