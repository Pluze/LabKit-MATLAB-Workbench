% Private UI runtime helper. Expected callers: v2 runtime construction and
% event commits. Inputs are candidate semantic state and its v2 definition.
% Side effect: rejects noncanonical roots, missing buckets, runtime resources,
% and app-invalid project payloads before a live commit.
function validateV2State(state, def)
    if ~isstruct(state) || ~isscalar(state)
        invalid('State must be a scalar struct.');
    end
    roots = string(fieldnames(state));
    if ~isequal(sort(roots), sort(["project"; "session"]))
        invalid('State root fields must be exactly project and session.');
    end
    validateBuckets(state.project, ...
        ["inputs", "parameters", "annotations", "results", "extensions"], ...
        "project");
    validateBuckets(state.session, ...
        ["selection", "workflow", "view", "cache"], "session");
    if isstruct(state.project.inputs) && isscalar(state.project.inputs) && ...
            isfield(state.project.inputs, 'sources')
        validateSourceRecords(state.project.inputs.sources);
    end
    try
        validateSerializableState(state);
    catch ME
        if strcmp(ME.identifier, 'labkit:ui:runtime:UnserializableState')
            error('labkit:ui:runtime:InvalidState', '%s', ME.message);
        end
        rethrow(ME);
    end
    runProjectValidator(def.project.Validate, state.project);
end

function validateBuckets(value, required, label)
    if ~isstruct(value) || ~isscalar(value)
        invalid('State %s must be a scalar struct.', label);
    end
    missing = setdiff(required, string(fieldnames(value)));
    if ~isempty(missing)
        invalid('State %s is missing required bucket(s): %s.', ...
            label, strjoin(cellstr(missing), ', '));
    end
end

function runProjectValidator(validator, project)
    count = nargout(validator);
    if count == 0
        validator(project);
        return;
    end
    accepted = validator(project);
    if ~isempty(accepted) && ...
            ~(islogical(accepted) && isscalar(accepted) && accepted)
        invalid('Project.Validate must return true, return empty, or throw.');
    end
end

function invalid(message, varargin)
    error('labkit:ui:runtime:InvalidState', message, varargin{:});
end
