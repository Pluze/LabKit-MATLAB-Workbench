% Private UI runtime helper. Expected caller: v2 project storage. Inputs are
% the current runtime and optional resume data. Output is a validated,
% serializable labkit.project envelope containing only durable app project data.
function envelope = createV2ProjectEnvelope(runtime, resume)
    if nargin < 2 || isempty(resume)
        resume = struct();
    end
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
    envelope.sources = projectSources(runtime.state.project);
    envelope.payload = runtime.state.project;
    envelope.resume = resume;
    if ~isfield(envelope, 'provenance')
        envelope.provenance = struct();
    end
    if ~isfield(envelope, 'extensions')
        envelope.extensions = struct();
    end
    validateSerializableState(envelope);
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
