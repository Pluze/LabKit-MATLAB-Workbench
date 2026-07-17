% Private Runtime V2 source-schema owner. Expected callers are the public
% empty-source factory and injected project services. Inputs are scalar source
% metadata. Output is one canonical durable source record with no file IO.
function source = canonicalSourceRecord(id, role, sourceValue, required)
    if ~(ischar(id) || (isstring(id) && isscalar(id)))
        error('labkit:ui:runtime:InvalidSourceRecords', ...
            'Project source id must be nonempty scalar text.');
    end
    id = string(id);
    if ~isscalar(id) || strlength(id) == 0
        error('labkit:ui:runtime:InvalidSourceRecords', ...
            'Project source id must be nonempty scalar text.');
    end
    reference = canonicalReference(sourceValue);
    source = struct( ...
        "id", id, ...
        "required", logical(required), ...
        "role", string(role), ...
        "reference", reference);
end

function reference = canonicalReference(value)
    if ~isstruct(value)
        filepath = string(value);
        [~, name, extension] = fileparts(filepath);
        reference = struct( ...
            "schemaVersion", 1, ...
            "relativePath", "", ...
            "originalPath", filepath, ...
            "fileName", string(name) + string(extension));
        return;
    end
    requiredFields = ["schemaVersion", "relativePath", ...
        "originalPath", "fileName"];
    if ~isscalar(value) || ...
            ~all(isfield(value, cellstr(requiredFields)))
        invalid(['Existing portable reference must be a scalar struct with ' ...
            'the canonical fields.']);
    end
    versionValue = double(value.schemaVersion);
    if ~isscalar(versionValue) || ~isfinite(versionValue) || ...
            versionValue ~= 1
        invalid('Existing portable reference has an unsupported schema version.');
    end
    relativePath = scalarText(value.relativePath, 'relative path', true);
    originalPath = scalarText(value.originalPath, 'original path', true);
    fileName = scalarText(value.fileName, 'file name', false);
    if strlength(relativePath) == 0 && strlength(originalPath) == 0
        invalid(['Existing portable reference must contain a relative or ' ...
            'original path.']);
    end
    reference = struct( ...
        "schemaVersion", 1, ...
        "relativePath", relativePath, ...
        "originalPath", originalPath, ...
        "fileName", fileName);
end

function value = scalarText(value, label, allowEmpty)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        invalid('Existing portable reference %s must be scalar text.', label);
    end
    value = string(value);
    if ~allowEmpty && strlength(value) == 0
        invalid('Existing portable reference %s must be nonempty.', label);
    end
end

function invalid(message, varargin)
    error('labkit:ui:runtime:InvalidSourceRecords', message, varargin{:});
end
