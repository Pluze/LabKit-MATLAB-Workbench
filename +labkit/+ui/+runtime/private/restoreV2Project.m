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
    [project, resume, envelope, needsUpgrade] = readV2ProjectFile( ...
        filepath, runtime.definition);
    sources = struct([]);
    if isstruct(envelope) && isfield(envelope, 'sources')
        sources = envelope.sources;
    end
    validateV2Project(project);
    validateProjectPayload(runtime.definition.project.Validate, project);
    services = buildV2RuntimeServices(fig, runtime, @(varargin) []);
    [project, resolvedSources, relinkedSources] = resolveV2ProjectSources( ...
        project, sources, filepath, runtime.definition.project, services);
    session = createFreshSession(runtime.definition, project, resume);
    session.cache.resolvedSources = resolvedSources;
    nextState = struct("project", project, "session", session);
    validateV2State(nextState, runtime.definition);
    runtime.state = nextState;
    runtime.document = documentFromEnvelope(runtime.document, envelope, filepath);
    if relinkedSources || needsUpgrade
        runtime.document.dirty = true;
    end
    if asRecovery
        runtime.document.path = "";
        runtime.document.dirty = true;
    end
    runtime.document.loading = true;
    try
        % A replacement project owns a fresh session and must repaint every
        % preview even when its semantic model equals the prior document.
        runtime.lastPresentation = struct();
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
    try
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
    catch cause
        failure = MException( ...
            'labkit:ui:runtime:ProjectSessionRestoreFailed', ...
            'Could not rebuild the project session from %s: %s', ...
            sourceDescription(project), cause.message);
        failure = addCause(failure, cause);
        throw(failure);
    end
end

function description = sourceDescription(project)
    description = "project state";
    if ~isfield(project, 'inputs') || ~isstruct(project.inputs) || ...
            ~isfield(project.inputs, 'sources') || ...
            isempty(project.inputs.sources)
        return;
    end
    sources = project.inputs.sources;
    paths = labkit.ui.runtime.sourcePaths(sources);
    count = min(numel(sources), 5);
    labels = strings(count, 1);
    for k = 1:count
        id = string(sources(k).id);
        role = string(sources(k).role);
        [~, name, extension] = fileparts(paths(k));
        filename = string(name) + string(extension);
        if strlength(filename) == 0
            filename = "(unresolved)";
        end
        labels(k) = sprintf('inputs.sources id "%s" role "%s" file "%s"', ...
            id, role, filename);
    end
    description = join(labels, "; ");
    if numel(sources) > count
        description = description + sprintf( ...
            '; and %d additional source record(s)', numel(sources) - count);
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
