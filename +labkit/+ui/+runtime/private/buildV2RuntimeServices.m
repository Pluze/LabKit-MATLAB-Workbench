% Private UI runtime service factory. Expected caller: runV2App. Inputs are
% the current figure/runtime and the queue dispatch callback. Output exposes
% app-neutral event, dialog, source, result, and resource mechanics to V2
% handlers without growing the public labkit.ui surface.
function services = buildV2RuntimeServices(fig, runtime, dispatch)
    services = struct();
    services.figure = fig;
    services.debug = runtime.debug;
    services.request = runtime.request;
    services.dispatch = dispatch;
    services.workflow = struct( ...
        "log", @(state, message) appendWorkflowLog( ...
            state, runtime.debug, message));
    services.diagnostics = struct( ...
        "report", @(context, exception) reportException( ...
            runtime.debug, runtime.definition.id, context, exception));
    services.events = struct( ...
        "entries", @eventEntries, ...
        "paths", @eventPaths, ...
        "indices", @eventIndices);
    services.dialogs = struct( ...
        "alert", @(message, titleText) labkit.ui.runtime.showAlert( ...
            fig, message, titleText), ...
        "defaultFolder", @labkit.ui.runtime.defaultDialogFolder, ...
        "defaultOutputFolder", @labkit.ui.runtime.defaultOutputFolder, ...
        "inputFile", @(filter, titleText, startPath) inputFile( ...
            runtime.request, filter, titleText, startPath), ...
        "outputFile", @(filter, titleText, defaultPath) outputFile( ...
            runtime.request, filter, titleText, defaultPath), ...
        "outputFolder", @(titleText, defaultPath) outputFolder( ...
            runtime.request, titleText, defaultPath));
    services.project = struct( ...
        "sourceRecord", @sourceRecord, ...
        "upsertSource", @upsertSource, ...
        "reconcileSources", @reconcileSources);
    services.resources = struct( ...
        "set", @(scope, id, value, cleanup) v2ResourceRegistry( ...
            fig, "set", scope, id, value, cleanup), ...
        "get", @(scope, id) v2ResourceRegistry(fig, "get", scope, id), ...
        "remove", @(scope, id) v2ResourceRegistry(fig, "remove", scope, id), ...
        "clearScope", @(scope) v2ResourceRegistry(fig, "clearScope", scope));
    services.results = struct( ...
        "output", @resultOutput, ...
        "writeManifest", @(folder, spec) writeResultManifest( ...
            fig, folder, spec));
end

function state = appendWorkflowLog(state, debugLog, message)
    line = string(message);
    if ~isscalar(line)
        line = join(line(:), newline);
    end
    if ~isfield(state.session.workflow, 'logLines')
        state.session.workflow.logLines = strings(0, 1);
    end
    state.session.workflow.logLines(end + 1, 1) = line;
    if isfield(state.session.workflow, 'statusMessage')
        state.session.workflow.statusMessage = line;
    end
    if isDebugEnabled(debugLog) && isfield(debugLog, 'append')
        debugLog.append(char(line));
    end
end

function reportException(debugLog, appId, context, exception)
    if isstruct(debugLog) && isfield(debugLog, 'reportException')
        debugLog.reportException(char(string(appId)), ...
            char(string(context)), exception);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end

function values = eventEntries(event, fieldName)
    values = [];
    if isstruct(event) && isfield(event, 'meta') && ...
            isstruct(event.meta) && isfield(event.meta, 'original') && ...
            isstruct(event.meta.original) && ...
            isfield(event.meta.original, char(fieldName))
        values = event.meta.original.(char(fieldName));
    end
end

function paths = eventPaths(event, fieldName)
    values = eventEntries(event, fieldName);
    if isstruct(values) && isfield(values, 'path')
        paths = string({values.path}).';
    else
        paths = string(values(:));
    end
    paths = paths(strlength(paths) > 0);
end

function indices = eventIndices(event, fieldName, count)
    values = eventEntries(event, fieldName);
    indices = zeros(0, 1);
    if isstruct(values) && isfield(values, 'id')
        tokens = regexp(string({values.id}), '^item(\d+)$', ...
            'tokens', 'once');
        for k = 1:numel(tokens)
            if ~isempty(tokens{k})
                indices(end + 1, 1) = str2double(tokens{k}{1});
            end
        end
    end
    if isempty(indices) && isstruct(values) && isfield(values, 'path')
        allValues = eventEntries(event, "files");
        if isstruct(allValues) && isfield(allValues, 'path')
            [~, indices] = ismember(string({values.path}), ...
                string({allValues.path}));
        end
    end
    indices = unique(indices(indices >= 1 & indices <= count), 'stable');
end

function [pathValue, cancelled] = inputFile( ...
        request, filter, titleText, startPath)
    chooser = @uigetfile;
    args = chooserArgs(request, ["inputFileChooser", "inputChooser"]);
    if ~isempty(args)
        chooser = args{2};
    end
    [file, folder] = chooser(filter, titleText, startPath);
    cancelled = isequal(file, 0) || isequal(folder, 0);
    if cancelled
        pathValue = "";
    else
        pathValue = string(fullfile(folder, file));
    end
end

function [pathValue, cancelled] = outputFile( ...
        request, filter, titleText, defaultPath)
    args = chooserArgs(request, ["outputFileChooser", "outputChooser"]);
    [pathValue, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        filter, titleText, defaultPath, args{:});
end

function [folder, cancelled] = outputFolder(request, titleText, defaultPath)
    args = chooserArgs(request, "outputFolderChooser");
    [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
        titleText, defaultPath, args{:});
end

function args = chooserArgs(request, names)
    args = {};
    if ~isstruct(request) || ~isscalar(request)
        return;
    end
    for name = string(names)
        field = char(name);
        if isfield(request, field) && isa(request.(field), 'function_handle')
            args = {'Chooser', request.(field)};
            return;
        end
    end
end

function source = sourceRecord(id, role, filepath, required)
    if nargin < 4
        required = true;
    end
    filepath = string(filepath);
    [~, name, extension] = fileparts(filepath);
    reference = struct( ...
        "schemaVersion", 1, ...
        "relativePath", "", ...
        "originalPath", filepath, ...
        "fileName", string(name) + string(extension));
    source = struct( ...
        "id", string(id), ...
        "required", logical(required), ...
        "role", string(role), ...
        "reference", reference);
end

function sources = upsertSource(sources, id, role, filepath, required)
    if nargin < 5
        required = true;
    end
    source = sourceRecord(id, role, filepath, required);
    if isempty(sources)
        sources = source;
        return;
    end
    match = find(string({sources.id}) == source.id, 1, 'first');
    if isempty(match)
        sources(end + 1) = source;
    else
        sources(match) = source;
    end
end

function sources = reconcileSources(existing, paths, role, idPrefix, required)
    if nargin < 5
        required = true;
    end
    paths = string(paths(:));
    sources = repmat(sourceRecord("", role, "", required), 0, 1);
    for k = 1:numel(paths)
        match = sourceIndexForPath(existing, paths(k));
        if isempty(match)
            id = nextSourceId(existing, sources, idPrefix);
            source = sourceRecord(id, role, paths(k), required);
        else
            source = existing(match);
        end
        sources(end + 1, 1) = source;
    end
end

function index = sourceIndexForPath(sources, filepath)
    index = [];
    for k = 1:numel(sources)
        if string(sources(k).reference.originalPath) == string(filepath)
            index = k;
            return;
        end
    end
end

function id = nextSourceId(existing, added, prefix)
    ids = [string({existing.id}), string({added.id})];
    number = numel(existing) + numel(added) + 1;
    id = string(prefix) + "-" + string(number);
    while any(ids == id)
        number = number + 1;
        id = string(prefix) + "-" + string(number);
    end
end

function output = resultOutput(id, role, pathValue, mediaType, status, message)
    if nargin < 5
        status = "success";
    end
    if nargin < 6
        message = "";
    end
    output = struct( ...
        "Id", string(id), ...
        "Role", string(role), ...
        "Path", string(pathValue), ...
        "MediaType", string(mediaType), ...
        "Status", string(status), ...
        "Message", string(message));
end

function varargout = writeResultManifest(fig, folder, spec)
    runtime = getappdata(fig, appRuntimeKey());
    runtime.document.exporting = true;
    setappdata(fig, appRuntimeKey(), runtime);
    cleanup = onCleanup(@() clearExporting(fig));
    [varargout{1:nargout}] = writeV2ResultManifest(runtime, folder, spec);
    clear cleanup;
end

function clearExporting(fig)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, appRuntimeKey())
        return;
    end
    runtime = getappdata(fig, appRuntimeKey());
    runtime.document.exporting = false;
    setappdata(fig, appRuntimeKey(), runtime);
end
