classdef (Hidden, Sealed) ResultWriter < handle
    % Private atomic writer for one explicit Result package.
    % Apps use RuntimeContext.writeResult.

    properties (Access = private)
        Application
        Document
    end

    methods (Access = ?labkit.app.internal.RuntimeKernel)
        function obj = ResultWriter(application, document)
            if ~isa(application, "labkit.app.Definition")
                invalid("Result writer requires an Application value.");
            end
            obj.Application = application;
            obj.Document = documentMetadata(document);
        end

        function written = write(obj, folder, result)
            folder = packageFolder(folder);
            if ~isa(result, "labkit.app.result.Package")
                invalid("Result writer requires a Result value.");
            end
            if ~isfolder(folder) && ~mkdir(folder)
                invalid("Could not create result package folder.");
            end

            outputs = verifiedOutputs(folder, result.Outputs);
            manifest = resultManifest( ...
                obj.Application, obj.Document, result, outputs);
            manifestPath = fullfile(folder, result.ManifestName);
            writeAtomic(manifestPath, manifest);
            written = labkit.app.dialog.Choice(string(manifestPath));
        end
    end
end

function metadata = documentMetadata(value)
    if nargin == 0 || isempty(value)
        metadata = [];
        return;
    end
    if ~isstruct(value) || ~isscalar(value) || ...
            ~all(isfield(value, ["id", "revision"]))
        invalid("Document metadata must be empty or contain id and revision.");
    end
    id = scalarText(value.id, "Document id");
    revision = value.revision;
    if strlength(id) == 0 || ~(isnumeric(revision) && isscalar(revision) && ...
            isfinite(revision) && revision >= 0 && revision == fix(revision))
        invalid("Document metadata is invalid.");
    end
    metadata = struct("id", id, "revision", uint64(revision));
end

function folder = packageFolder(value)
    folder = scalarText(value, "Result folder");
    if strlength(folder) == 0
        invalid("Result folder must be nonempty.");
    end
end

function outputs = verifiedOutputs(folder, declarations)
    template = struct("id", "", "role", "", "relativePath", "", ...
        "mediaType", "", "bytes", uint64(0), "sha256", "", ...
        "status", "", "message", "", "warnings", strings(0, 1));
    outputs = repmat(template, 1, numel(declarations));
    for k = 1:numel(declarations)
        declaration = declarations{k};
        status = declaration.Status;
        message = declaration.Message;
        bytes = uint64(0);
        digest = "";
        if status == "success"
            target = packagePath(folder, declaration.RelativePath);
            if ~isfile(target)
                status = "failed";
                message = "Output file was not found after export.";
            else
                details = dir(target);
                bytes = uint64(details.bytes);
                digest = sha256File(target);
            end
        end
        outputs(k) = struct( ...
            "id", declaration.Id, "role", declaration.Role, ...
            "relativePath", declaration.RelativePath, ...
            "mediaType", declaration.MediaType, "bytes", bytes, ...
            "sha256", digest, "status", status, "message", message, ...
            "warnings", declaration.Warnings);
    end
end

function path = packagePath(folder, relativePath)
    parts = cellstr(split(relativePath, "/"));
    path = fullfile(folder, parts{:});
end

function manifest = resultManifest(application, document, result, outputs)
    manifest = struct( ...
        "format", "labkit.result", ...
        "formatVersion", struct("major", 1, "minor", 0), ...
        "app", struct("id", application.AppId, ...
            "version", application.AppVersion), ...
        "run", struct("id", newId(), "createdAtUtc", utcNow(), ...
            "status", aggregateStatus(outputs)), ...
        "inputs", result.Inputs, "parameters", result.Parameters, ...
        "outputs", outputs, "summary", result.Summary, ...
        "provenance", struct( ...
            "labkitAppVersion", string(labkit.app.version().current), ...
            "matlabRelease", string(version("-release")), ...
            "platform", string(computer), "warnings", result.Warnings));
    if ~isempty(document)
        manifest.project = struct("documentId", document.id, ...
            "revision", document.revision);
    end
end

function value = aggregateStatus(outputs)
    statuses = string({outputs.status});
    if all(statuses == "success")
        value = "success";
    elseif all(statuses == "failed")
        value = "failed";
    else
        value = "partial";
    end
end

function digest = sha256File(filepath)
    file = fopen(filepath, "rb");
    if file < 0
        invalid("Could not read exported output for checksum.");
    end
    cleanup = onCleanup(@() fclose(file));
    algorithm = java.security.MessageDigest.getInstance("SHA-256");
    while true
        buffer = fread(file, 65536, "*uint8");
        if isempty(buffer)
            break;
        end
        algorithm.update(typecast(buffer, "int8"));
    end
    raw = typecast(algorithm.digest(), "uint8");
    digest = lower(string(reshape(dec2hex(raw, 2).', 1, [])));
    clear cleanup
end

function writeAtomic(filepath, manifest)
    try
        payload = jsonencode(manifest, PrettyPrint=true);
    catch cause
        failure = MException("labkit:app:runtime:InvalidResultManifest", ...
            "Result manifest is not JSON serializable.");
        failure = addCause(failure, cause);
        throwAsCaller(failure);
    end
    temporary = string(filepath) + ".tmp";
    cleanup = onCleanup(@() deleteIfPresent(temporary));
    file = fopen(temporary, "w");
    if file < 0
        invalid("Could not create result manifest temporary file.");
    end
    fileCleanup = onCleanup(@() fclose(file));
    fwrite(file, payload, "char");
    clear fileCleanup
    [moved, message] = movefile(temporary, filepath, "f");
    if ~moved
        invalid("Could not replace result manifest: %s.", message);
    end
    clear cleanup
end

function value = scalarText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        invalid("%s must be scalar text.", label);
    end
    value = string(value);
end

function value = newId()
    value = string(char(java.util.UUID.randomUUID()));
end

function value = utcNow()
    value = string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
end

function deleteIfPresent(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end

function invalid(message, varargin)
    error("labkit:app:runtime:InvalidResultManifest", message, varargin{:});
end
