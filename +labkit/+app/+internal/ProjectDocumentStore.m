classdef (Hidden, Sealed) ProjectDocumentStore < handle
    % Private durable-project storage for RuntimeKernel.
    properties (SetAccess = private)
        Metadata (1, 1) struct
    end

    properties (Access = private)
        Application
        Context
        Sources
    end

    methods (Access = ?labkit.app.internal.RuntimeKernel)
        function obj = ProjectDocumentStore(application, context)
            if ~isa(application, "labkit.app.Definition") || ...
                    isempty(application.ProjectSchema) || ...
                    ~isa(context, "labkit.app.CallbackContext")
                error("labkit:app:runtime:InvariantFailure", ...
                    "Project document storage requires an Application with Project.");
            end
            obj.Application = application;
            obj.Context = context;
            obj.Sources = labkit.app.internal.PortableSourceStore();
            nowUtc = utcNow();
            obj.Metadata = struct( ...
                "id", newId(), ...
                "createdAtUtc", nowUtc, ...
                "modifiedAtUtc", nowUtc, ...
                "revision", uint64(0), ...
                "path", "", ...
                "dirty", true);
        end

        function result = save(obj, state, filepath)
            filepath = projectPath(filepath);
            candidate = obj.nextSavedMetadata(filepath);
            envelope = obj.envelope(state, candidate);
            writeProjectFile(filepath, envelope);
            obj.Metadata = candidate;
            result = labkit.app.dialog.Choice(filepath, Cancelled=false);
        end

        function saveRecovery(obj, state, filepath)
            filepath = projectPath(filepath);
            candidate = obj.Metadata;
            candidate.path = filepath;
            envelope = obj.envelope(state, candidate);
            writeProjectFile(filepath, envelope);
        end

        function [state, metadata] = restore(obj, filepath, asRecovery)
            filepath = projectPath(filepath);
            if nargin < 3
                asRecovery = false;
            end
            if ~(islogical(asRecovery) && isscalar(asRecovery))
                error("labkit:app:contract:InvalidValue", ...
                    "Project restore asRecovery must be logical scalar.");
            end
            [project, resume, document] = obj.readProject(filepath);
            project = obj.migrate(project, document.payloadVersion);
            project = obj.resolveBoundSources(project, filepath);
            obj.validateProject(project);
            session = obj.createSession(project, resume);
            state = struct("project", project, "session", session);
            candidate = document.metadata;
            candidate.path = filepath;
            candidate.dirty = false;
            if asRecovery
                candidate.path = "";
                candidate.dirty = true;
            end
            metadata = candidate;
        end

        function acceptRestore(obj, metadata)
            obj.Metadata = metadata;
        end

        function markDirty(obj)
            if ~obj.Metadata.dirty
                obj.Metadata.dirty = true;
                obj.Metadata.modifiedAtUtc = utcNow();
            end
        end
    end

    methods (Access = private)
        function envelope = envelope(obj, state, metadata)
            obj.validateState(state);
            resume = struct();
            contract = obj.Application.ProjectSchema;
            if ~isempty(contract.CreateResume)
                resume = contract.CreateResume(state.session, state.project);
                if isempty(resume)
                    resume = struct();
                end
            end
            sdk = labkit.app.version();
            [project, sources] = obj.rebaseBoundSources( ...
                state.project, metadata.path);
            envelope = struct( ...
                "format", "labkit.project", ...
                "formatVersion", struct("major", 1, "minor", 0), ...
                "app", struct("id", obj.Application.AppId, ...
                    "payloadVersion", double(contract.Version)), ...
                "document", documentEnvelope(metadata), ...
                "producer", struct( ...
                    "appVersion", obj.Application.AppVersion, ...
                    "labkitAppVersion", string(sdk.current), ...
                    "matlabRelease", string(version("-release")), ...
                    "platform", string(computer)), ...
                "sources", sources, ...
                "payload", project, ...
                "resume", resume);
        end

        function [project, resume, decoded] = readProject(obj, filepath)
            details = whos("-file", char(filepath));
            names = string({details.name});
            legacy = string(fieldnames(obj.Application.ProjectSchema.LegacyImports)).';
            recognized = intersect(names, ["labkitProject", legacy]);
            if numel(recognized) ~= 1
                error("labkit:app:runtime:UnknownProjectFormat", ...
                    "Project file must contain exactly one recognized state variable.");
            end
            name = recognized(1);
            loaded = load(char(filepath), char(name));
            if name == "labkitProject"
                [project, resume, decoded] = obj.decodeEnvelope(loaded.labkitProject);
                return;
            end
            importer = obj.Application.ProjectSchema.LegacyImports.(char(name));
            if nargout(importer) == 2
                [project, resume] = importer(loaded.(char(name)));
            else
                project = importer(loaded.(char(name)));
                resume = struct();
            end
            decoded = struct("payloadVersion", double(obj.Application.ProjectSchema.Version), ...
                "metadata", obj.newImportedMetadata());
        end

        function [project, resume, decoded] = decodeEnvelope(obj, envelope)
            requireStruct(envelope, "project envelope");
            requireFields(envelope, ["format", "formatVersion", "app", ...
                "document", "producer", "payload", "resume"], "project envelope");
            if string(envelope.format) ~= "labkit.project"
                invalidProject("Unsupported project format.");
            end
            requireFields(envelope.formatVersion, ["major", "minor"], ...
                "formatVersion");
            major = positiveInteger(envelope.formatVersion.major, ...
                "Project format major version");
            if major > 1
                error("labkit:app:runtime:NewerProjectFormat", ...
                    "Project format major version is newer than this LabKit reader.");
            elseif major ~= 1
                invalidProject("Unsupported project format major version.");
            end
            requireFields(envelope.app, ["id", "payloadVersion"], "app");
            if string(envelope.app.id) ~= obj.Application.AppId
                error("labkit:app:runtime:WrongProjectApp", ...
                    "Project app id does not match the running app.");
            end
            project = envelope.payload;
            resume = envelope.resume;
            decoded = struct( ...
                "payloadVersion", positiveInteger(envelope.app.payloadVersion, ...
                    "Project payload version"), ...
                "metadata", metadataFromEnvelope(envelope.document));
        end

        function project = migrate(obj, project, fromVersion)
            current = double(obj.Application.ProjectSchema.Version);
            if fromVersion > current
                error("labkit:app:runtime:NewerProjectPayload", ...
                    "Project payload version is newer than supported version.");
            end
            for version = fromVersion:current - 1
                project = obj.Application.ProjectSchema.Migrate(project, version);
            end
        end

        function [project, collected] = rebaseBoundSources( ...
                obj, project, filepath)
            bindings = obj.projectSourceBindings();
            collected = struct([]);
            for path = bindings
                sources = getProjectBinding(project, path);
                sources = obj.Sources.rebase(sources, filepath);
                project = setProjectBinding(project, path, sources);
                if isempty(collected)
                    collected = sources;
                elseif ~isempty(sources)
                    collected = [collected; sources];
                end
            end
        end

        function project = resolveBoundSources(obj, project, filepath)
            for path = obj.projectSourceBindings()
                sources = getProjectBinding(project, path);
                [resolved, unresolved] = obj.Sources.resolve( ...
                    sources, filepath);
                project = setProjectBinding(project, path, resolved);
                if isempty(unresolved)
                    continue;
                end
                callback = obj.Application.ProjectSchema.RelinkSources;
                if isempty(callback)
                    error("labkit:app:runtime:MissingProjectSource", ...
                        "Project has unresolved required source files.");
                end
                project = callback(project, unresolved, filepath);
                if isempty(project)
                    error("labkit:app:runtime:ProjectLoadCancelled", ...
                        "Project source relinking was cancelled.");
                end
                sources = getProjectBinding(project, path);
                [resolved, remaining] = obj.Sources.resolve( ...
                    sources, filepath);
                if ~isempty(remaining)
                    error("labkit:app:runtime:MissingProjectSource", ...
                        "Project source relinking left required files unresolved.");
                end
                project = setProjectBinding(project, path, resolved);
            end
        end

        function bindings = projectSourceBindings(obj)
            plan = obj.Application.platformPlanForRuntime();
            bindings = strings(1, 0);
            for k = 1:numel(plan.Nodes)
                node = plan.Nodes(k);
                if node.Kind ~= "fileList" || ...
                        ~isfield(node.Configuration, "Bind")
                    continue;
                end
                path = node.Configuration.Bind;
                if startsWith(path, "project.")
                    bindings(end + 1) = extractAfter(path, "project.");
                end
            end
            bindings = unique(bindings, "stable");
        end

        function validateProject(obj, project)
            if ~isstruct(project) || ~isscalar(project)
                invalidProject("Project payload must be a scalar struct.");
            end
            accepted = obj.Application.ProjectSchema.Validate(project);
            if ~(islogical(accepted) && isscalar(accepted) && accepted)
                invalidProject("Project.Validate rejected the loaded project payload.");
            end
        end

        function session = createSession(obj, project, resume)
            if isempty(obj.Application.CreateSession)
                session = struct();
            else
                session = obj.Application.CreateSession(project, obj.Context);
            end
            if ~isstruct(session) || ~isscalar(session)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Application Session must return a scalar struct.");
            end
            apply = obj.Application.ProjectSchema.ApplyResume;
            if ~isempty(apply) && ~isempty(resume)
                session = apply(session, resume, project);
            end
            if ~isstruct(session) || ~isscalar(session)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Project ApplyResume must return a scalar session struct.");
            end
        end

        function validateState(obj, state)
            if ~isstruct(state) || ~isscalar(state) || ...
                    ~all(isfield(state, ["project", "session"])) || ...
                    ~isstruct(state.session) || ~isscalar(state.session)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Project save requires scalar project/session state.");
            end
            obj.validateProject(state.project);
        end

        function metadata = nextSavedMetadata(obj, filepath)
            metadata = obj.Metadata;
            metadata.modifiedAtUtc = utcNow();
            metadata.revision = metadata.revision + uint64(1);
            metadata.path = filepath;
            metadata.dirty = false;
        end

        function metadata = newImportedMetadata(~)
            nowUtc = utcNow();
            metadata = struct("id", newId(), "createdAtUtc", nowUtc, ...
                "modifiedAtUtc", nowUtc, "revision", uint64(0), ...
                "path", "", "dirty", true);
        end
    end
end

function value = getProjectBinding(project, path)
parts = cellstr(split(path, "."));
value = project;
for k = 1:numel(parts)
    name = parts{k};
    if ~isstruct(value) || ~isscalar(value) || ~isfield(value, name)
        invalidProject("Bound source path is absent: project.%s.", path);
    end
    value = value.(name);
end
end

function project = setProjectBinding(project, path, value)
project = assignProjectField(project, cellstr(split(path, ".")), value, path);
end

function owner = assignProjectField(owner, parts, value, path)
name = parts{1};
if ~isstruct(owner) || ~isscalar(owner) || ~isfield(owner, name)
    invalidProject("Bound source path is absent: project.%s.", path);
end
if numel(parts) == 1
    owner.(name) = value;
else
    owner.(name) = assignProjectField( ...
        owner.(name), parts(2:end), value, path);
end
end

function writeProjectFile(filepath, labkitProject)
folder = string(fileparts(filepath));
if strlength(folder) == 0
    folder = string(pwd);
    filepath = fullfile(folder, filepath);
end
if ~isfolder(folder)
    error("labkit:app:runtime:ProjectWriteFailed", ...
        "Project destination folder does not exist: %s.", folder);
end
temporary = string(tempname(folder)) + ".mat";
cleanup = onCleanup(@() deleteIfPresent(temporary));
save(char(temporary), "labkitProject");
inventory = whos("-file", char(temporary));
if numel(inventory) ~= 1 || string(inventory.name) ~= "labkitProject"
    error("labkit:app:runtime:ProjectWriteFailed", ...
        "Temporary project readback inventory was invalid.");
end
readback = load(char(temporary), "labkitProject");
if ~isequaln(readback.labkitProject, labkitProject)
    error("labkit:app:runtime:ProjectWriteFailed", ...
        "Temporary project readback did not match the encoded document.");
end
[moved, message] = movefile(char(temporary), char(filepath), "f");
if ~moved
    error("labkit:app:runtime:ProjectWriteFailed", ...
        "Could not replace project file: %s.", message);
end
clear cleanup
end

function value = projectPath(value)
if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
        strlength(string(value)) == 0
    error("labkit:app:contract:InvalidValue", ...
        "Project filepath must be nonempty scalar text.");
end
value = string(value);
end

function value = positiveInteger(value, label)
if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
        value >= 1 && value == fix(value))
    invalidProject("%s must be a positive integer.", label);
end
value = double(value);
end

function metadata = metadataFromEnvelope(value)
requireFields(value, ["id", "createdAtUtc", "modifiedAtUtc", "revision"], ...
    "document");
metadata = struct( ...
    "id", scalarText(value.id, "document id"), ...
    "createdAtUtc", scalarText(value.createdAtUtc, "document createdAtUtc"), ...
    "modifiedAtUtc", scalarText(value.modifiedAtUtc, "document modifiedAtUtc"), ...
    "revision", uint64(positiveInteger(value.revision + 1, ...
        "document revision") - 1), ...
    "path", "", "dirty", true);
end

function value = documentEnvelope(metadata)
value = rmfield(metadata, ["path", "dirty"]);
end

function requireStruct(value, label)
if ~isstruct(value) || ~isscalar(value)
    invalidProject("%s must be a scalar struct.", label);
end
end

function requireFields(value, fields, label)
requireStruct(value, label);
for k = 1:numel(fields)
    if ~isfield(value, fields(k))
        invalidProject("%s is missing field %s.", label, fields(k));
    end
end
end

function value = scalarText(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    invalidProject("%s must be scalar text.", label);
end
value = string(value);
end

function value = utcNow()
value = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
end

function value = newId()
value = string(char(java.util.UUID.randomUUID()));
end

function deleteIfPresent(filepath)
if isfile(filepath)
    delete(filepath);
end
end

function invalidProject(message, varargin)
error("labkit:app:runtime:InvalidProject", message, varargin{:});
end
