classdef (Hidden, Sealed) PortableSourceStore < handle
    % Private portable-source representation and resolution owner.
    %
    % RuntimeKernel and ProjectDocumentStore use this class to create and
    % relocate durable source references.  App code never receives this
    % storage owner or relies on the nested reference representation.

    methods (Access = {?labkit.app.internal.RuntimeKernel, ?labkit.app.internal.ProjectDocumentStore})
        function obj = PortableSourceStore()
        end

        function record = create(~, id, role, pathOrReference, required)
            if nargin < 5
                required = true;
            end
            record = makeRecord(id, role, pathOrReference, required);
        end

        function paths = sourcePaths(~, records, ids)
            validateRecords(records);
            recordIds = recordIdsOf(records);
            indices = (1:numel(records)).';
            if nargin >= 3
                requested = normalizeIds(ids, "Requested source ids");
                if isempty(requested)
                    paths = strings(0, 1);
                    return;
                end
                [~, indices] = ismember(requested, recordIds);
            end
            paths = strings(numel(indices), 1);
            for k = 1:numel(indices)
                if indices(k) ~= 0
                    paths(k) = records(indices(k)).reference.originalPath;
                end
            end
        end

        function records = upsert(~, records, record)
            validateRecords(records);
            validateRecord(record);
            if isempty(records)
                records = reshape(record, 1, 1);
                return;
            end
            match = find(recordIdsOf(records) == record.id, 1, "first");
            if isempty(match)
                records(end + 1, 1) = record;
            else
                records(match) = record;
            end
        end

        function records = reconcile(~, current, incoming)
            % Incoming records are the complete desired collection and order.
            % Validate both sides before returning a canonical replacement so
            % callers never partially publish malformed source state.
            validateRecords(current);
            validateRecords(incoming);
            records = canonicalCollection(incoming);
        end

        function records = reconcilePaths(obj, current, paths, role, prefix, required)
            validateRecords(current);
            paths = normalizePaths(paths);
            role = requiredText(role, "Project source role");
            prefix = requiredText(prefix, "Project source id prefix");
            records = emptyRecords();
            for k = 1:numel(paths)
                currentPaths = obj.sourcePaths(current);
                match = find(currentPaths == paths(k), 1);
                if isempty(match)
                    id = nextId(current, records, prefix);
                    record = obj.create(id, role, paths(k), required);
                else
                    record = current(match);
                end
                records = appendRecord(records, record);
            end
        end

        function records = recordsForRole(~, records, role)
            validateRecords(records);
            role = requiredText(role, "Project source role");
            if isempty(records)
                records = emptyRecords();
                return;
            end
            records = canonicalCollection(records( ...
                string({records.role}) == role));
        end

        function records = reconcileRolePaths(obj, current, paths, ...
                role, prefix, required)
            validateRecords(current);
            role = requiredText(role, "Project source role");
            currentRole = obj.recordsForRole(current, role);
            replacement = obj.reconcilePaths( ...
                currentRole, paths, role, prefix, required);
            if isempty(current)
                records = replacement;
                return;
            end
            roleMask = string({current.role}) == role;
            insertion = find(roleMask, 1, "first");
            if isempty(insertion)
                records = canonicalCollection(current);
                for k = 1:numel(replacement)
                    records = appendRecord(records, replacement(k));
                end
                return;
            end
            records = emptyRecords();
            for k = 1:numel(current)
                if k == insertion
                    for n = 1:numel(replacement)
                        records = appendRecord(records, replacement(n));
                    end
                end
                if ~roleMask(k)
                    records = appendRecord(records, current(k));
                end
            end
        end

        function records = rebase(~, records, projectFile)
            validateRecords(records);
            projectFile = requiredPath(projectFile, "Project filepath");
            records = canonicalCollection(records);
            for k = 1:numel(records)
                target = records(k).reference.originalPath;
                records(k).reference = makeReference(projectFile, target);
            end
        end

        function [resolved, unresolved] = resolve(~, records, projectFile)
            validateRecords(records);
            projectFile = requiredPath(projectFile, "Project filepath");
            resolved = emptyRecords();
            unresolved = emptyRecords();
            for k = 1:numel(records)
                [pathValue, ~] = resolveReference(projectFile, records(k).reference);
                if strlength(pathValue) > 0
                    record = records(k);
                    record.reference = makeReference(projectFile, pathValue);
                    resolved = appendRecord(resolved, record);
                elseif records(k).required
                    unresolved = appendRecord(unresolved, records(k));
                end
            end
        end
    end

end

function record = makeRecord(id, role, pathOrReference, required)
id = requiredText(id, "Project source id");
role = requiredText(role, "Project source role");
if ~(islogical(required) || isnumeric(required)) || ~isscalar(required) || ...
        ~isfinite(double(required)) || ~any(double(required) == [0 1])
    invalid("Project source required flag must be scalar logical.");
end
record = struct("id", id, "required", logical(required), "role", role, ...
    "reference", {canonicalReference(pathOrReference)});
end

function records = canonicalCollection(records)
if isempty(records)
    records = emptyRecords();
    return;
end
output = emptyRecords();
for k = 1:numel(records)
    record = records(k);
    output = appendRecord(output, makeRecord( ...
        record.id, record.role, record.reference, record.required));
end
records = output;
end

function records = appendRecord(records, record)
if isempty(records)
    records = reshape(record, 1, 1);
else
    records(end + 1, 1) = record;
end
end

function records = emptyRecords()
reference = struct("schemaVersion", 1, "relativePath", "", ...
    "originalPath", "", "fileName", "");
prototype = struct("id", "", "required", true, "role", "", ...
    "reference", {reference});
records = repmat(prototype, 0, 1);
end

function validateRecords(records)
if isempty(records)
    if ~isstruct(records)
        invalid("Project source records must be a struct array.");
    end
    return;
end
if ~isstruct(records)
    invalid("Project source records must be a struct array.");
end
ids = strings(numel(records), 1);
for k = 1:numel(records)
    validateRecord(records(k));
    ids(k) = records(k).id;
end
if numel(unique(ids, "stable")) ~= numel(ids)
    [~, first] = unique(ids, "stable");
    repeated = ids(setdiff((1:numel(ids)).', first, "stable"));
    invalid("Project source ids must be unique; duplicate ""%s"".", repeated);
end
end

function validateRecord(record)
if ~isstruct(record) || ~isscalar(record) || ...
        ~isequal(string(fieldnames(record)), ...
            ["id"; "required"; "role"; "reference"])
    invalid("Project source record must have the canonical fields.");
end
makeRecord(record.id, record.role, record.reference, record.required);
end

function ids = recordIdsOf(records)
if isempty(records)
    ids = strings(0, 1);
else
    ids = string({records.id}).';
end
end

function value = canonicalReference(value)
if ~isstruct(value)
    pathValue = requiredPath(value, "Project source filepath");
    value = makeReference("", pathValue);
    return;
end
fields = ["schemaVersion"; "relativePath"; "originalPath"; "fileName"];
if ~isscalar(value) || ~isequal(string(fieldnames(value)), fields)
    invalid("Portable reference must have the canonical fields.");
end
version = value.schemaVersion;
if ~(isnumeric(version) && isscalar(version) && isfinite(version) && version == 1)
    invalid("Portable reference has an unsupported schema version.");
end
relative = optionalText(value.relativePath, "Portable relative path");
original = optionalText(value.originalPath, "Portable original path");
fileName = requiredText(value.fileName, "Portable file name");
if strlength(relative) == 0 && strlength(original) == 0
    invalid("Portable reference must include a relative or original path.");
end
value = struct("schemaVersion", 1, "relativePath", relative, ...
    "originalPath", original, "fileName", fileName);
end

function reference = makeReference(projectFile, targetPath)
targetPath = requiredPath(targetPath, "Project source filepath");
[~, name, extension] = fileparts(targetPath);
reference = struct("schemaVersion", 1, "relativePath", "", ...
    "originalPath", targetPath, "fileName", string(name) + string(extension));
if strlength(string(projectFile)) > 0
    folder = string(fileparts(projectFile));
    reference.relativePath = relativeToFolder(folder, targetPath);
end
end

function [targetPath, matchKind] = resolveReference(projectFile, reference)
folder = string(fileparts(projectFile));
candidates = strings(0, 1);
kinds = strings(0, 1);
if strlength(reference.relativePath) > 0
    parts = cellstr(split(replace(reference.relativePath, "\", "/"), "/"));
    candidates(end + 1, 1) = fullfile(folder, parts{:});
    kinds(end + 1, 1) = "relative";
end
if strlength(reference.originalPath) > 0
    candidates(end + 1, 1) = reference.originalPath;
    kinds(end + 1, 1) = "original";
end
if strlength(reference.fileName) > 0
    candidates(end + 1, 1) = fullfile(folder, reference.fileName);
    kinds(end + 1, 1) = "same_folder";
end
targetPath = "";
matchKind = "none";
for k = 1:numel(candidates)
    [exists, attributes] = fileattrib(char(candidates(k)));
    if exists && ~attributes.directory
        targetPath = string(attributes.Name);
        matchKind = kinds(k);
        return;
    end
end
end

function relative = relativeToFolder(folder, target)
folder = replace(string(folder), "\", "/");
target = replace(string(target), "\", "/");
if ~isAbsolutePath(target)
    relative = target;
    return;
end
folderParts = split(strip(folder, "/"), "/");
targetParts = split(strip(target, "/"), "/");
limit = min(numel(folderParts), numel(targetParts));
common = 0;
while common < limit && strcmpi(folderParts(common + 1), targetParts(common + 1))
    common = common + 1;
end
if common == 0
    relative = "";
    return;
end
parents = repmat("..", numel(folderParts) - common, 1);
relative = join([parents; targetParts(common + 1:end)], "/");
end

function tf = isAbsolutePath(pathValue)
tf = startsWith(pathValue, "/") || startsWith(pathValue, "\") || ...
    ~isempty(regexp(pathValue, '^[A-Za-z]:/', 'once'));
end

function ids = normalizeIds(value, label)
if ~(ischar(value) || isstring(value) || iscellstr(value))
    invalid("%s must be text.", label);
end
ids = string(value);
ids = ids(:);
if any(strlength(ids) == 0)
    invalid("%s must be nonempty.", label);
end
end

function paths = normalizePaths(value)
if ~(ischar(value) || isstring(value) || iscellstr(value))
    invalid("Source paths must be text.");
end
paths = string(value(:));
if any(strlength(paths) == 0)
    invalid("Source paths must be nonempty.");
end
end

function id = nextId(current, pending, prefix)
ids = [recordIdsOf(current); recordIdsOf(pending)];
index = 1;
id = prefix + "-" + index;
while any(ids == id)
    index = index + 1;
    id = prefix + "-" + index;
end
end

function value = requiredPath(value, label)
value = requiredText(value, label);
end

function value = requiredText(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
        strlength(string(value)) == 0
    invalid("%s must be nonempty scalar text.", label);
end
value = string(value);
end

function value = optionalText(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    invalid("%s must be scalar text.", label);
end
value = string(value);
end

function invalid(message, varargin)
error("labkit:app:runtime:InvalidSourceRecords", message, varargin{:});
end
