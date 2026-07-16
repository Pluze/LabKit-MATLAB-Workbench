% Private UI runtime helper. Expected caller: runV2App. Input is a validated
% v2 definition. Output is the canonical project/session semantic state.
function state = createV2State(def)
    project = def.project.Create();
    project = addRequiredBuckets(project, ...
        ["inputs", "parameters", "annotations", "results", "extensions"], ...
        "project");
    session = createSession(def.createSession, project);
    session = addRequiredBuckets(session, ...
        ["selection", "workflow", "view", "cache"], "session");
    state = struct("project", project, "session", session);
    validateV2State(state, def);
end

function session = createSession(factory, project)
    if isempty(factory)
        session = struct();
        return;
    end
    count = nargin(factory);
    if count == 0
        session = factory();
    else
        session = factory(project);
    end
end

function value = addRequiredBuckets(value, names, label)
    if isempty(value)
        value = struct();
    end
    if ~isstruct(value) || ~isscalar(value)
        error('labkit:ui:runtime:InvalidState', ...
            'The %s factory must return a scalar struct.', label);
    end
    for k = 1:numel(names)
        field = char(names(k));
        if ~isfield(value, field)
            value.(field) = struct();
        end
    end
end
