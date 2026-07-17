% App-owned durable Gait Analysis contract. Runtime V2 calls the single
% migration entry for each missing version before validating current sources,
% analysis parameters, and durable results.
function spec = projectSpec()
    spec = struct( ...
        "Version", 3, ...
        "Create", @createProject, ...
        "Validate", @validateProject, ...
        "Migrate", @migrateProject);
end

function project = createProject()
    project = struct();
    project.inputs = struct("sources", ...
        labkit.ui.runtime.emptySourceRecords());
    project.parameters = gait_analysis.analysisRun.defaultOptions();
    project.annotations = struct();
    project.results = struct( ...
        "analysis", gait_analysis.analysisRun.emptyResult(), ...
        "lastExport", []);
    project.extensions = struct();
end

function project = migrateProject(project, fromVersion)
    switch double(fromVersion)
        case 1
            project = migrateVersionOne(project);
        case 2
            project = migrateVersionTwo(project);
        otherwise
            error('gait_analysis:UnsupportedProjectMigration', ...
                'Gait Analysis cannot migrate project version %d.', ...
                fromVersion);
    end
end

function project = migrateVersionOne(project)
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
    defaults = gait_analysis.analysisRun.defaultOptions();
    names = string(fieldnames(defaults));
    for k = 1:numel(names)
        name = char(names(k));
        if ~isfield(project.parameters, name)
            project.parameters.(name) = defaults.(name);
        end
    end
    project.results.analysis = gait_analysis.analysisRun.emptyResult();
    project.results.lastExport = [];
end

function project = migrateVersionTwo(project)
    project.inputs.sources = project.inputs.source;
    project.inputs = rmfield(project.inputs, 'source');
end

function accepted = validateProject(project)
    assert(isfield(project.inputs, 'sources'), ...
        'gait_analysis:InvalidProject', 'Gait project source is missing.');
    defaults = gait_analysis.analysisRun.defaultOptions();
    fields = fieldnames(defaults);
    assert(all(isfield(project.parameters, fields)), ...
        'gait_analysis:InvalidProject', 'Gait parameters are incomplete.');
    numericFields = ["frameRate", "pixelsPerUnit", "smoothWindow", ...
        "detectionProminence", "detectionMinHeightSigma", ...
        "minLiftOffIntervalSeconds", "minSwingFrames", ...
        "maxSwingFrames", "minStepLength", "maxHipTranslation"];
    for name = numericFields
        value = double(project.parameters.(name));
        assert(isscalar(value) && isfinite(value), ...
            'gait_analysis:InvalidProject', ...
            'Gait numeric parameter is invalid.');
    end
    assert(all(isfield(project.results, {'analysis', 'lastExport'})) && ...
        isstruct(project.results.analysis) && ...
        isscalar(project.results.analysis), ...
        'gait_analysis:InvalidProject', 'Gait result state is invalid.');
    accepted = true;
end
