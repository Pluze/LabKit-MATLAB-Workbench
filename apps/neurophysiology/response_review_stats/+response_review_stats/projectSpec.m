% App-owned durable Response Review Stats contract. App SDK runtime upgrades the
% former singular source through the one migration entry, then validates metric
% windows and durable export state.
function spec = projectSpec()
    spec = labkit.app.project.Schema(Version=2, ...
        Create=@createProject, Validate=@validateProject, Migrate=@migrateProject, ...
        SourceBindings="inputs.sources");
end

function project = createProject()
    project = struct();
    project.inputs = struct("sources", ...
        struct([]));
    project.parameters = struct( ...
        "baselineWindowSec", [0.007 0.009], ...
        "noiseWindowSec", [0.007 0.009]);
    project.annotations = struct();
    project.results = struct("lastExport", []);
    project.extensions = struct();
end

function project = migrateProject(project, fromVersion)
    switch double(fromVersion)
        case 1
            project.inputs.sources = project.inputs.source;
            project.inputs = rmfield(project.inputs, 'source');
        otherwise
            error('response_review_stats:UnsupportedProjectMigration', ...
                ['Response Review Stats cannot migrate project ' ...
                'version %d.'], fromVersion);
    end
end

function accepted = validateProject(project)
    assert(isfield(project.inputs, 'sources'), ...
        'response_review_stats:InvalidProject', ...
        'Response Review Stats sources are incomplete.');
    parameters = project.parameters;
    assert(all(isfield(parameters, ...
        {'baselineWindowSec', 'noiseWindowSec'})) && ...
        validRange(parameters.baselineWindowSec) && ...
        validRange(parameters.noiseWindowSec), ...
        'response_review_stats:InvalidProject', ...
        'Response Review Stats metric windows are invalid.');
    assert(isfield(project.results, 'lastExport'), ...
        'response_review_stats:InvalidProject', ...
        'Response Review Stats result state is invalid.');
    accepted = true;
end

function tf = validRange(value)
    value = double(value);
    tf = isequal(size(value), [1 2]) && all(isfinite(value));
end
