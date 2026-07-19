classdef (Hidden, Sealed) ResourceStore < handle
    % Private parent-owned disposable resource store.
    properties (Access = private)
        Entries
    end

    methods (Access = ?labkit.ui.RuntimeKernel)
        function obj = ResourceStore()
            obj.Entries = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
        end

        function set(obj, scope, id, value, cleanup)
            key = resourceKey(scope, id);
            if isKey(obj.Entries, key)
                obj.dispose(obj.Entries(key));
            end
            obj.Entries(key) = struct( ...
                "Scope", string(scope), "Id", string(id), ...
                "Value", value, "Cleanup", cleanup);
        end

        function value = get(obj, scope, id)
            key = resourceKey(scope, id);
            if ~isKey(obj.Entries, key)
                value = [];
                return;
            end
            entry = obj.Entries(key);
            value = entry.Value;
        end

        function remove(obj, scope, id)
            key = resourceKey(scope, id);
            if ~isKey(obj.Entries, key)
                return;
            end
            entry = obj.Entries(key);
            remove(obj.Entries, key);
            obj.dispose(entry);
        end

        function clearScope(obj, scope)
            keys = string(obj.Entries.keys);
            selected = startsWith(keys, string(scope) + "|");
            failures = {};
            for key = keys(selected)
                entry = obj.Entries(char(key));
                remove(obj.Entries, char(key));
                try
                    obj.dispose(entry);
                catch cause
                    failures{end + 1} = cause;
                end
            end
            if ~isempty(failures)
                failure = MException( ...
                    "labkit:ui:runtime:ResourceCleanupFailed", ...
                    "One or more %s resources failed to clean up.", scope);
                for k = 1:numel(failures)
                    failure = addCause(failure, failures{k});
                end
                throwAsCaller(failure);
            end
        end

        function clearAll(obj)
            failures = {};
            for scope = ["event", "interaction", "document", "application"]
                try
                    obj.clearScope(scope);
                catch cause
                    failures{end + 1} = cause;
                end
            end
            if ~isempty(failures)
                failure = MException( ...
                    "labkit:ui:runtime:ResourceCleanupFailed", ...
                    "One or more runtime resources failed to clean up.");
                for k = 1:numel(failures)
                    failure = addCause(failure, failures{k});
                end
                throwAsCaller(failure);
            end
        end
    end

    methods (Static, Access = private)
        function dispose(entry)
            if isempty(entry.Cleanup)
                return;
            end
            entry.Cleanup(entry.Value);
        end
    end
end

function key = resourceKey(scope, id)
    key = char(string(scope) + "|" + string(id));
end
