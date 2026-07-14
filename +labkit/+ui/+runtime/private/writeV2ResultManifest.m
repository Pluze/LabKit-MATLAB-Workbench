% Private UI runtime helper. Expected caller: v2 handler result services.
% Inputs are the current runtime, result package folder, and app-owned spec.
% Outputs are the JSON manifest path and normalized labkit.result envelope.
% Side effects calculate completed-file metadata and atomically write JSON.
function [manifestPath, manifest] = writeV2ResultManifest(runtime, folder, spec)
    folder = string(folder);
    if ~isfolder(folder)
        mkdir(folder);
    end
    if ~isstruct(spec) || ~isscalar(spec)
        invalid('Result specification must be a scalar struct.');
    end
    outputs = normalizeOutputs(folder, requiredValue(spec, 'Outputs'));
    manifest = struct( ...
        "format", "labkit.result", ...
        "formatVersion", struct("major", 1, "minor", 0), ...
        "app", struct("id", string(runtime.definition.id), ...
            "version", appVersion(runtime)), ...
        "run", struct("id", newId(), "createdAtUtc", utcNow(), ...
            "status", aggregateStatus(outputs)), ...
        "inputs", optionValue(spec, 'Inputs', struct([])), ...
        "parameters", optionValue(spec, 'Parameters', struct()), ...
        "outputs", outputs, ...
        "summary", optionValue(spec, 'Summary', struct()), ...
        "provenance", struct( ...
            "labkitUiVersion", uiVersion(), ...
            "matlabRelease", string(version("-release")), ...
            "platform", string(computer), ...
            "warnings", optionValue(spec, 'Warnings', strings(1, 0))), ...
        "extensions", optionValue(spec, 'Extensions', struct()));
    if strlength(runtime.document.id) > 0
        manifest.project = struct("documentId", runtime.document.id, ...
            "revision", runtime.document.revision);
    end
    validateSerializableState(manifest);
    manifestName = optionValue(spec, 'ManifestName', '');
    if strlength(string(manifestName)) == 0
        manifestName = defaultManifestName(outputs);
    end
    manifestName = normalizedRelativePath(manifestName);
    if contains(manifestName, "/")
        invalid('Result manifest name must stay in the package root.');
    end
    manifestPath = fullfile(folder, manifestName);
    writeJsonAtomic(manifestPath, manifest);
end

function name = defaultManifestName(outputs)
    if numel(outputs) == 1 && strlength(outputs(1).relativePath) > 0
        [~, base, ~] = fileparts(outputs(1).relativePath);
        name = string(base) + ".labkit.json";
    else
        name = "labkit_result.json";
    end
end

function outputs = normalizeOutputs(folder, values)
    if ~isstruct(values)
        invalid('Result Outputs must be a struct array.');
    end
    outputs = struct("id", {}, "role", {}, "relativePath", {}, ...
        "mediaType", {}, "bytes", {}, "sha256", {}, "status", {}, ...
        "message", {});
    for k = 1:numel(values)
        relativePath = normalizedRelativePath(requiredValue(values(k), 'Path'));
        status = string(optionValue(values(k), 'Status', 'success'));
        message = string(optionValue(values(k), 'Message', ''));
        bytes = uint64(0);
        digest = "";
        if status == "success"
            target = packagePath(folder, relativePath);
            if ~isfile(target)
                status = "failed";
                message = "Output file was not found after export.";
            else
                details = dir(target);
                bytes = uint64(details.bytes);
                digest = sha256File(target);
            end
        end
        outputs(end + 1) = struct( ...
            "id", string(requiredValue(values(k), 'Id')), ...
            "role", string(requiredValue(values(k), 'Role')), ...
            "relativePath", relativePath, ...
            "mediaType", string(optionValue(values(k), 'MediaType', ...
                'application/octet-stream')), ...
            "bytes", bytes, "sha256", digest, "status", status, ...
            "message", message);
    end
end

function path = normalizedRelativePath(value)
    path = replace(string(value), "\", "/");
    if ~isscalar(path) || strlength(path) == 0 || startsWith(path, "/") || ...
            startsWith(path, "//") || ~isempty(regexp(char(path), ...
            '^[A-Za-z]:', 'once'))
        invalid('Result output paths must be relative package paths.');
    end
    parts = split(path, "/");
    if any(parts == "..") || any(parts == "")
        invalid('Result output paths must not traverse package boundaries.');
    end
    path = join(parts, "/");
end

function target = packagePath(folder, relativePath)
    parts = cellstr(split(relativePath, "/"));
    target = string(fullfile(folder, parts{:}));
end

function digest = sha256File(filepath)
    file = fopen(filepath, 'rb');
    if file < 0
        invalid('Could not read exported output for checksum.');
    end
    cleanup = onCleanup(@() fclose(file));
    algorithm = java.security.MessageDigest.getInstance('SHA-256');
    while true
        buffer = fread(file, 65536, '*uint8');
        if isempty(buffer)
            break;
        end
        algorithm.update(typecast(buffer, 'int8'));
    end
    raw = typecast(algorithm.digest(), 'uint8');
    digest = lower(string(reshape(dec2hex(raw, 2).', 1, [])));
    clear cleanup;
end

function writeJsonAtomic(filepath, value)
    temporary = string(filepath) + ".tmp";
    cleanup = onCleanup(@() deleteIfPresent(temporary));
    file = fopen(temporary, 'w');
    if file < 0
        invalid('Could not create result manifest temporary file.');
    end
    fileCleanup = onCleanup(@() fclose(file));
    fwrite(file, jsonencode(value, PrettyPrint=true), 'char');
    clear fileCleanup;
    [moved, message] = movefile(temporary, filepath, 'f');
    if ~moved
        invalid('Could not replace result manifest: %s.', message);
    end
    clear cleanup;
end

function value = requiredValue(spec, name)
    if ~isfield(spec, name)
        invalid('Result specification is missing %s.', name);
    end
    value = spec.(name);
end

function value = optionValue(spec, name, defaultValue)
    value = defaultValue;
    if isstruct(spec) && isfield(spec, name)
        value = spec.(name);
    end
end

function value = aggregateStatus(outputs)
    statuses = string({outputs.status});
    if isempty(statuses) || all(statuses == "success")
        value = "success";
    elseif all(statuses == "failed")
        value = "failed";
    else
        value = "partial";
    end
end

function value = appVersion(runtime)
    value = "";
    if isappdata(runtime.ui.figure, 'labkitUiAppVersion')
        info = getappdata(runtime.ui.figure, 'labkitUiAppVersion');
        if isstruct(info) && isfield(info, 'version')
            value = string(info.version);
        end
    end
end

function value = uiVersion()
    info = labkit.ui.version();
    value = string(info.current);
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
    error('labkit:ui:runtime:InvalidResultManifest', message, varargin{:});
end
