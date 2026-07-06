% Private UI runtime helper. Expected caller: labkit.ui.runtime.loadState. Inputs are
% a LabKit app figure and MAT-file path. Side effect: atomically replaces the
% semantic runtime state only after snapshot compatibility and serialization
% checks succeed.
function restoreSnapshot(fig, filepath)
    runtime = getAppRuntime(fig);
    loaded = load(filepath, 'snapshot');
    if ~isfield(loaded, 'snapshot')
        error('labkit:ui:runtime:InvalidSnapshot', ...
            'State snapshot file must contain one variable named snapshot.');
    end
    snapshot = loaded.snapshot;
    validateSnapshot(snapshot, runtime);

    nextState = snapshot.state;
    spec = snapshotSpec(runtime.definition);
    if isfield(spec, 'Deserialize') && isa(spec.Deserialize, 'function_handle')
        nextState = invokeHook(spec.Deserialize, nextState, ...
            runtimeServices(runtime), 1);
    end
    validateSerializableState(nextState);

    previousRuntime = runtime;
    nextRuntime = runtime;
    nextRuntime.state = nextState;
    try
        setappdata(fig, appRuntimeKey(), nextRuntime);
        renderAppRuntime(fig);
        runAfterLoad(fig, spec);
    catch ME
        setappdata(fig, appRuntimeKey(), previousRuntime);
        try
            renderAppRuntime(fig);
        catch
        end
        rethrow(ME);
    end
end

function validateSnapshot(snapshot, runtime)
    if ~isstruct(snapshot) || ~isscalar(snapshot) || ...
            ~isfield(snapshot, 'schema') || ...
            string(snapshot.schema) ~= "labkit.ui.runtime.snapshot.v1"
        error('labkit:ui:runtime:InvalidSnapshot', ...
            'Unsupported LabKit app snapshot schema.');
    end
    required = ["app", "labkit", "state"];
    for k = 1:numel(required)
        if ~isfield(snapshot, required(k))
            error('labkit:ui:runtime:InvalidSnapshot', ...
                'State snapshot is missing field "%s".', required(k));
        end
    end
    if string(snapshot.app.id) ~= string(runtime.definition.id)
        error('labkit:ui:runtime:IncompatibleSnapshot', ...
            'Snapshot app id "%s" does not match current app id "%s".', ...
            char(string(snapshot.app.id)), char(string(runtime.definition.id)));
    end
    uiVersion = labkit.ui.version();
    assertSameString(snapshot.labkit.uiVersion, uiVersion.current, ...
        'LabKit UI version');
    assertSameString(snapshot.labkit.matlabRelease, version("-release"), ...
        'MATLAB release');
    assertSameString(snapshot.labkit.platform, computer, 'platform');
    spec = snapshotSpec(runtime.definition);
    assertSameString(snapshot.app.snapshotVersion, snapshotVersion(spec), ...
        'app snapshot version');
    currentAppVersion = appVersionString(runtime);
    if strlength(currentAppVersion) > 0 || strlength(string(snapshot.app.version)) > 0
        assertSameString(snapshot.app.version, currentAppVersion, 'app version');
    end
end

function assertSameString(actual, expected, label)
    if string(actual) ~= string(expected)
        error('labkit:ui:runtime:IncompatibleSnapshot', ...
            'Snapshot %s "%s" does not match current "%s".', ...
            char(label), char(string(actual)), char(string(expected)));
    end
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

function runAfterLoad(fig, spec)
    if ~(isfield(spec, 'AfterLoad') && isa(spec.AfterLoad, 'function_handle'))
        return;
    end
    runtime = getAppRuntime(fig);
    nextState = invokeHook(spec.AfterLoad, runtime.state, ...
        runtimeServices(runtime), 1);
    if ~isequal(nextState, runtime.state)
        validateSerializableState(nextState);
        runtime.state = nextState;
        setappdata(fig, appRuntimeKey(), runtime);
        renderAppRuntime(fig);
    end
end

function services = runtimeServices(runtime)
    services = struct();
    services.figure = runtime.ui.figure;
    services.ui = runtime.ui;
    services.debug = runtime.debug;
end

function out = invokeHook(hook, state, services, defaultOutputCount)
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
