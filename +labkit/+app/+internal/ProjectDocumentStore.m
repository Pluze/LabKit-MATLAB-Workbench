classdef (Hidden, Sealed) ProjectDocumentStore < handle
    % Private durable-project storage for RuntimeKernel.
    properties (SetAccess = private)
        Metadata (1, 1) struct
    end

    properties (Access = private)
        Application
        Contract
        Context
        Sources
        AcceptedPath (1, 1) string = ""
        AcceptedFingerprint (1, 1) string = ""
        PendingPath (1, 1) string = ""
        PendingFingerprint (1, 1) string = ""
    end

    methods (Access = ?labkit.app.internal.RuntimeKernel)
        function obj = ProjectDocumentStore(application, context, contract)
            if ~isa(application, "labkit.app.Definition") || ...
                    isempty(application.ProjectSchema) || ...
                    ~isa(context, "labkit.app.CallbackContext") || ...
                    ~isa(contract, "labkit.app.internal.CompiledDefinition")
                error("labkit:app:runtime:InvariantFailure", ...
                    "Project document storage requires an Application with Project.");
            end
            obj.Application = application;
            obj.Contract = contract;
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
            obj.assertNoExternalOverwrite(filepath);
            candidate = obj.nextSavedMetadata(filepath);
            envelope = obj.envelope(state, candidate);
            writeProjectFile(filepath, envelope);
            obj.Metadata = candidate;
            obj.acceptFile(filepath);
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
            if asRecovery
                obj.PendingPath = "";
                obj.PendingFingerprint = "";
            else
                obj.PendingPath = filepath;
                obj.PendingFingerprint = fileFingerprint(filepath);
            end
        end

        function [state, metadata] = createNew(obj)
            project = obj.Application.ProjectSchema.Create();
            obj.validateProject(project);
            session = obj.createSession(project, []);
            state = struct("project", project, "session", session);
            metadata = obj.newImportedMetadata();
        end

        function acceptRestore(obj, metadata)
            obj.Metadata = metadata;
            obj.AcceptedPath = obj.PendingPath;
            obj.AcceptedFingerprint = obj.PendingFingerprint;
            obj.PendingPath = "";
            obj.PendingFingerprint = "";
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
            schema = obj.Application.ProjectSchema;
            if ~schema.UsesInferredSourceBindings
                bindings = schema.SourceBindings;
                return;
            end
            plan = obj.Contract.PlatformPlan;
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

        function assertNoExternalOverwrite(obj, filepath)
            if strlength(obj.AcceptedPath) == 0 || ...
                    ~samePath(filepath, obj.AcceptedPath)
                return;
            end
            if ~isfile(filepath) || ...
                    fileFingerprint(filepath) ~= obj.AcceptedFingerprint
                error("labkit:app:runtime:ProjectWriteConflict", ...
                    "Project file changed after it was opened or saved: %s.", ...
                    filepath);
            end
        end

        function acceptFile(obj, filepath)
            obj.AcceptedPath = filepath;
            obj.AcceptedFingerprint = fileFingerprint(filepath);
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

function value = fileFingerprint(filepath)
stream = fopen(char(filepath), "r");
if stream < 0
    error("labkit:app:runtime:ProjectReadFailed", ...
        "Could not read project file for conflict detection: %s.", filepath);
end
cleanup = onCleanup(@() fclose(stream));
digest = java.security.MessageDigest.getInstance("SHA-256");
while true
    bytes = fread(stream, 1024 * 1024, "*uint8");
    if isempty(bytes)
        break;
    end
    digest.update(typecast(bytes, "int8"));
end
value = lower(string(reshape(dec2hex(typecast(digest.digest(), "uint8"), 2).', 1, [])));
clear cleanup
end

function tf = samePath(left, right)
left = java.nio.file.Paths.get(char(left), javaArray("java.lang.String", 0));
right = java.nio.file.Paths.get(char(right), javaArray("java.lang.String", 0));
tf = string(left.toAbsolutePath().normalize().toString()) == ...
    string(right.toAbsolutePath().normalize().toString());
if ispc
    tf = lower(string(left.toAbsolutePath().normalize().toString())) == ...
        lower(string(right.toAbsolutePath().normalize().toString()));
end
end

function invalidProject(message, varargin)
error("labkit:app:runtime:InvalidProject", message, varargin{:});
end
