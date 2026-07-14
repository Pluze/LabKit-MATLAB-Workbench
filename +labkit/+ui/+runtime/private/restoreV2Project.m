% Private UI runtime helper. Expected caller: loadState. Inputs are a v2 app
% figure and project path. Side effect validates/migrates off to the side, then
% replaces project plus a fresh session in one visible commit. Any failure
% restores the prior runtime and presentation.
function restoreV2Project(fig, filepath, asRecovery)
    if nargin < 3
        asRecovery = false;
    end
    runtime = getAppRuntime(fig);
    previous = runtime;
    [project, resume, envelope] = readV2ProjectFile( ...
        filepath, runtime.definition);
    sources = struct([]);
    if isstruct(envelope) && isfield(envelope, 'sources')
        sources = envelope.sources;
    end
    validateProjectPayload(runtime.definition.project.Validate, project);
    [project, resolvedSources] = resolveV2ProjectSources( ...
        project, sources, filepath, runtime.definition.project);
    session = createFreshSession(runtime.definition, project, resume);
    session.cache.resolvedSources = resolvedSources;
    nextState = struct("project", project, "session", session);
    validateV2State(nextState, runtime.definition);
    runtime.state = nextState;
    runtime.document = documentFromEnvelope(runtime.document, envelope, filepath);
    if asRecovery
        runtime.document.path = "";
        runtime.document.dirty = true;
    end
    runtime.document.loading = true;
    try
        setappdata(fig, appRuntimeKey(), runtime);
        presentation = commitV2Presentation(runtime, nextState);
        runtime = getAppRuntime(fig);
        runtime.lastPresentation = presentation;
        runtime.document.loading = false;
        runtime.metrics.stateCommits = runtime.metrics.stateCommits + 1;
        runtime.metrics.presentationCommits = ...
            runtime.metrics.presentationCommits + 1;
        setappdata(fig, appRuntimeKey(), runtime);
        updateV2DocumentTitle(fig);
    catch ME
        setappdata(fig, appRuntimeKey(), previous);
        try
            commitV2Presentation(previous, previous.state);
        catch
        end
        rethrow(ME);
    end
end

function validateProjectPayload(validator, project)
    if nargout(validator) == 0
        validator(project);
        return;
    end
    accepted = validator(project);
    if ~isempty(accepted) && ...
            ~(islogical(accepted) && isscalar(accepted) && accepted)
        error('labkit:ui:runtime:InvalidProject', ...
            'Project.Validate rejected the loaded project payload.');
    end
end

function session = createFreshSession(def, project, resume)
    if isempty(def.createSession)
        session = struct();
    elseif nargin(def.createSession) == 0
        session = def.createSession();
    else
        session = def.createSession(project);
    end
    required = ["selection", "workflow", "view", "cache"];
    for k = 1:numel(required)
        field = char(required(k));
        if ~isfield(session, field)
            session.(field) = struct();
        end
    end
    if isfield(def.project, 'ApplyResume') && ...
            isa(def.project.ApplyResume, 'function_handle') && ...
            ~isempty(resume)
        session = def.project.ApplyResume(session, resume, project);
    end
end

function document = documentFromEnvelope(current, envelope, filepath)
    document = current;
    if isstruct(envelope) && ~isempty(fieldnames(envelope)) && ...
            isfield(envelope, 'document')
        source = envelope.document;
        fields = ["id", "createdAtUtc", "modifiedAtUtc", "revision"];
        for k = 1:numel(fields)
            field = char(fields(k));
            if isfield(source, field)
                document.(field) = source.(field);
            end
        end
    else
        document.id = string(char(java.util.UUID.randomUUID()));
        document.revision = uint64(0);
    end
    document.path = string(filepath);
    document.dirty = false;
    document.envelope = envelope;
end
