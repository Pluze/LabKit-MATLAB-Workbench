% Private UI app helper. Expected caller: labkit.ui.app.saveState. Input is
% the current runtime struct. Output is one serializable snapshot struct with
% strict same-version metadata and app semantic state only.
function snapshot = createSnapshot(runtime)
    serializedState = runtime.state;
    spec = snapshotSpec(runtime.definition);
    if isfield(spec, 'Serialize') && isa(spec.Serialize, 'function_handle')
        serializedState = invokeSnapshotHook(spec.Serialize, runtime.state, ...
            runtimeServices(runtime), 1);
    end
    validateSerializableState(serializedState);

    snapshot = struct();
    snapshot.schema = "labkit.ui.app.snapshot.v1";
    snapshot.createdAt = datetime("now", "TimeZone", "local");
    snapshot.app = struct( ...
        "id", string(runtime.definition.id), ...
        "title", string(runtime.definition.title), ...
        "version", appVersionString(runtime), ...
        "snapshotVersion", snapshotVersion(spec));
    uiVersion = labkit.ui.version();
    snapshot.labkit = struct( ...
        "uiVersion", string(uiVersion.current), ...
        "matlabRelease", string(version("-release")), ...
        "platform", string(computer));
    snapshot.state = serializedState;
    snapshot.view = struct();
    snapshot.warnings = strings(0, 1);
end

function spec = snapshotSpec(definition)
    spec = struct();
    if isfield(definition, 'snapshot') && isstruct(definition.snapshot)
        spec = definition.snapshot;
    end
end

function value = snapshotVersion(spec)
    value = "";
    if isfield(spec, 'Version')
        value = string(spec.Version);
    end
end

function value = appVersionString(runtime)
    value = "";
    fig = runtime.ui.figure;
    if isappdata(fig, 'labkitUiAppVersion')
        info = getappdata(fig, 'labkitUiAppVersion');
        if isstruct(info) && isfield(info, 'version')
            value = string(info.version);
        end
    end
end

function services = runtimeServices(runtime)
    services = struct();
    services.figure = runtime.ui.figure;
    services.ui = runtime.ui;
    services.debug = runtime.debug;
end

function out = invokeSnapshotHook(hook, state, services, defaultOutputCount)
    n = nargout(hook);
    if n < 0
        n = defaultOutputCount;
    end
    argc = nargin(hook);
    if argc < 0
        argc = 2;
    end
    if n == 0
        if argc <= 1
            hook(state);
        else
            hook(state, services);
        end
        out = state;
    elseif argc <= 1
        out = hook(state);
    else
        out = hook(state, services);
    end
end
