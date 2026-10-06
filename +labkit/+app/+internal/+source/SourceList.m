classdef (Hidden, Sealed) SourceList
    % Stateless source-list reconciliation at the runtime boundary.
    methods (Static, Access = {?labkit.app.internal.runtime.RuntimeKernel, ...
            ?labkit.app.internal.runtime.RuntimePresentation})
        function records = recordsForRole(records, role)
            validateRecords(records);
            role = requiredText(role, "Source-list role");
            records = roleRecords(records, role);
        end

        function records = reconcileRolePaths(current, paths, role, prefix, allowDuplicatePaths)
            validateRecords(current);
            role = requiredText(role, "Source-list role");
            prefix = requiredText(prefix, "Source-list id prefix");
            paths = normalizePaths(paths);
            allowDuplicatePaths = logicalScalar( ...
                allowDuplicatePaths, "Allow duplicate source paths");
            if ~allowDuplicatePaths
                paths = unique(paths, "stable");
            end
            currentRole = roleRecords(current, role);
            currentPaths = string({currentRole.path}).';
            ids = string({currentRole.id}).';
            retained = false(numel(currentRole), 1);
            replacement = sourceRecords(numel(paths));
            nextIndex = 1;
            for k = 1:numel(paths)
                candidates = currentPaths == paths(k);
                if allowDuplicatePaths
                    candidates = candidates & ~retained;
                end
                match = find(candidates, 1);
                if isempty(match)
                    id = prefix + "-" + nextIndex;
                    while any(ids == id)
                        nextIndex = nextIndex + 1;
                        id = prefix + "-" + nextIndex;
                    end
                    nextIndex = nextIndex + 1;
                    replacement(k) = struct("id", id, "role", role, "path", paths(k));
                else
                    replacement(k) = currentRole(match);
                    retained(match) = true;
                end
            end
            records = spliceRole(current, role, replacement);
        end

        function records = replaceRole(current, role, replacement)
            validateRecords(current);
            validateRecords(replacement);
            role = requiredText(role, "Source-list role");
            if ~isempty(replacement) && any(string({replacement.role}) ~= role)
                invalid("Replacement source records must match role %s.", role);
            end
            records = spliceRole(current, role, replacement);
        end
    end
end

function records = roleRecords(records, role)
if isempty(records)
    records = sourceRecords(0);
else
    records = canonicalCollection(records(string({records.role}) == role));
end
end

function records = spliceRole(current, role, replacement)
if isempty(current)
    records = replacement;
    return;
end
roleMask = string({current.role}) == role;
insertion = find(roleMask, 1, "first");
if isempty(replacement)
    replacement = sourceRecords(0);
end
if isempty(insertion)
    records = [canonicalCollection(current); replacement(:)];
    return;
end
before = current(1:insertion - 1);
after = current(insertion:end);
after = after(~roleMask(insertion:end));
records = [before(:); replacement(:); after(:)];
end

function records = canonicalCollection(records)
if isempty(records)
    records = sourceRecords(0);
    return;
end
records = records(:);
for k = 1:numel(records)
    records(k).id = string(records(k).id);
    records(k).role = string(records(k).role);
    records(k).path = string(records(k).path);
end
end

function records = sourceRecords(count)
prototype = struct("id", "", "role", "", ...
    "path", "");
records = repmat(prototype, count, 1);
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
if ~isequal(string(fieldnames(records)), ["id"; "role"; "path"])
    invalid("Source-list record must have the canonical fields.");
end
ids = strings(numel(records), 1);
for k = 1:numel(records)
    record = records(k);
    requiredText(record.id, "Source-list id");
    requiredText(record.role, "Source-list role");
    requiredText(record.path, "Source filepath");
    ids(k) = records(k).id;
end
if numel(unique(ids, "stable")) ~= numel(ids)
    [~, first] = unique(ids, "stable");
    repeated = ids(setdiff((1:numel(ids)).', first, "stable"));
    invalid("Source-list ids must be unique; duplicate ""%s"".", repeated);
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
