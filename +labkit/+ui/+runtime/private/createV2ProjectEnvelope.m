% Private UI runtime helper. Expected caller: v2 project storage. Inputs are
% the current runtime, optional resume data, and actual destination path.
% Output is a validated, serializable labkit.project envelope containing only
% durable app project data with references rebased for that destination.
function envelope = createV2ProjectEnvelope(runtime, resume, filepath)
    if nargin < 2 || isempty(resume)
        resume = createResume(runtime);
    end
    if nargin < 3
        filepath = "";
    end
    project = rebaseProjectSources(runtime.state.project, filepath);
    document = runtime.document;
    document.modifiedAtUtc = utcNow();
    envelope = preservedEnvelope(runtime.document.envelope);
    envelope.format = "labkit.project";
    envelope.formatVersion = struct("major", 1, "minor", 0);
    envelope.app = struct("id", string(runtime.definition.id), ...
        "payloadVersion", double(runtime.definition.project.Version));
    envelope.document = struct( ...
        "id", document.id, ...
        "createdAtUtc", document.createdAtUtc, ...
        "modifiedAtUtc", document.modifiedAtUtc, ...
        "revision", document.revision);
    envelope.producer = producer(runtime);
    envelope.sources = projectSources(project);
    envelope.payload = project;
    envelope.resume = resume;
    if ~isfield(envelope, 'provenance')
        envelope.provenance = struct();
    end
    if ~isfield(envelope, 'extensions')
        envelope.extensions = struct();
    end
    validateSerializableState(envelope);
end

function resume = createResume(runtime)
    resume = struct();
    spec = runtime.definition.project;
    if ~isfield(spec, 'CreateResume') || ...
            ~isa(spec.CreateResume, 'function_handle')
        return;
    end
    resume = spec.CreateResume(runtime.state.session, runtime.state.project);
    if isempty(resume)
        resume = struct();
    end
end

function envelope = preservedEnvelope(value)
    if isstruct(value) && isscalar(value)
        envelope = value;
    else
        envelope = struct();
    end
end

function info = producer(runtime)
    appVersion = "";
    fig = runtime.ui.figure;
    if isappdata(fig, 'labkitUiAppVersion')
        versionInfo = getappdata(fig, 'labkitUiAppVersion');
        if isstruct(versionInfo) && isfield(versionInfo, 'version')
            appVersion = string(versionInfo.version);
        end
    end
    uiVersion = labkit.ui.version();
    info = struct( ...
        "appVersion", appVersion, ...
        "labkitUiVersion", string(uiVersion.current), ...
        "matlabRelease", string(version("-release")), ...
        "platform", string(computer));
end

function sources = projectSources(project)
    sources = struct([]);
    if isfield(project, 'inputs') && isstruct(project.inputs) && ...
            isfield(project.inputs, 'sources')
        sources = project.inputs.sources;
    end
end

function value = utcNow()
    value = string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
end
