classdef (Hidden, Sealed) SourceListStore < handle
    % Private UI source-list representation owner.

    methods (Access = ?labkit.app.internal.runtime.RuntimeKernel)
        function obj = SourceListStore()
        end

        function record = create(~, id, role, path, required)
            if nargin < 5
                required = true;
            end
            record = makeRecord(id, role, path, required);
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
                    paths(k) = records(indices(k)).path;
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

        function records = reconcilePaths(obj, current, paths, role, prefix, ...
                required, allowDuplicatePaths)
            validateRecords(current);
            paths = normalizePaths(paths);
            role = requiredText(role, "Source-list role");
            prefix = requiredText(prefix, "Source-list id prefix");
            if nargin < 7
                allowDuplicatePaths = false;
            end
            allowDuplicatePaths = logicalScalar( ...
                allowDuplicatePaths, "Allow duplicate source paths");
            if ~allowDuplicatePaths
                paths = unique(paths, "stable");
            end
            records = emptyRecords();
            currentPaths = obj.sourcePaths(current);
            retained = false(numel(current), 1);
            for k = 1:numel(paths)
                candidates = currentPaths == paths(k);
                if allowDuplicatePaths
                    candidates = candidates & ~retained;
                end
                match = find(candidates, 1);
                if isempty(match)
                    id = nextId(current, records, prefix);
                    record = obj.create(id, role, paths(k), required);
                else
                    record = current(match);
                    retained(match) = true;
                end
                records = appendRecord(records, record);
            end
        end

        function records = recordsForRole(~, records, role)
            validateRecords(records);
            role = requiredText(role, "Source-list role");
            if isempty(records)
                records = emptyRecords();
                return;
            end
            records = canonicalCollection(records( ...
                string({records.role}) == role));
        end

        function records = reconcileRolePaths(obj, current, paths, ...
                role, prefix, required, allowDuplicatePaths)
            validateRecords(current);
            role = requiredText(role, "Source-list role");
            if nargin < 7
                allowDuplicatePaths = false;
            end
            currentRole = obj.recordsForRole(current, role);
            replacement = obj.reconcilePaths( ...
                currentRole, paths, role, prefix, required, ...
                allowDuplicatePaths);
            records = obj.replaceRole(current, role, replacement);
        end

        function records = replaceRole(~, current, role, replacement)
            validateRecords(current);
            validateRecords(replacement);
            role = requiredText(role, "Source-list role");
            if ~isempty(replacement) && ...
                    any(string({replacement.role}) ~= role)
                invalid("Replacement source records must match role %s.", role);
            end
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

    end

end

function record = makeRecord(id, role, path, required)
id = requiredText(id, "Source-list id");
role = requiredText(role, "Source-list role");
if ~(islogical(required) || isnumeric(required)) || ~isscalar(required) || ...
        ~isfinite(double(required)) || ~any(double(required) == [0 1])
    invalid("Source-list required flag must be scalar logical.");
end
record = struct("id", id, "required", logical(required), "role", role, ...
    "path", requiredPath(path, "Source filepath"));
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
        record.id, record.role, record.path, record.required));
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
prototype = struct("id", "", "required", true, "role", "", ...
    "path", "");
records = repmat(prototype, 0, 1);
end

function validateRecords(records)
if isempty(records)
    if ~isstruct(records)
        invalid("Source-list records must be a struct array.");
    end
    return;
end
if ~isstruct(records)
    invalid("Source-list records must be a struct array.");
end
ids = strings(numel(records), 1);
for k = 1:numel(records)
    validateRecord(records(k));
    ids(k) = records(k).id;
end
if numel(unique(ids, "stable")) ~= numel(ids)
    [~, first] = unique(ids, "stable");
    repeated = ids(setdiff((1:numel(ids)).', first, "stable"));
    invalid("Source-list ids must be unique; duplicate ""%s"".", repeated);
end
end

function validateRecord(record)
if ~isstruct(record) || ~isscalar(record) || ...
        ~isequal(string(fieldnames(record)), ...
            ["id"; "required"; "role"; "path"])
    invalid("Source-list record must have the canonical fields.");
end
makeRecord(record.id, record.role, record.path, record.required);
end

function ids = recordIdsOf(records)
if isempty(records)
    ids = strings(0, 1);
else
    ids = string({records.id}).';
end
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
if isempty(value)
    paths = strings(0, 1);
elseif ischar(value)
    paths = string(value);
else
    paths = string(value(:));
end
if any(strlength(paths) == 0)
    invalid("Source paths must be nonempty.");
end
end

function value = logicalScalar(value, label)
if ~((islogical(value) || isnumeric(value)) && isscalar(value) && ...
        isfinite(double(value)) && any(double(value) == [0 1]))
    invalid("%s must be scalar logical.", label);
end
value = logical(value);
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

function invalid(message, varargin)
error("labkit:app:runtime:InvalidSourceRecords", message, varargin{:});
end
