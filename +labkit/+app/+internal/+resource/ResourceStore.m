classdef (Hidden, Sealed) ResourceStore < handle
    % Private parent-owned disposable resource store.
    properties (Access = private)
        Entries
    end

    methods (Access = ?labkit.app.internal.runtime.RuntimeKernel)
        function obj = ResourceStore()
            obj.Entries = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
        end

        function set(obj, id, value, cleanup)
            key = char(string(id));
            if isKey(obj.Entries, key)
                obj.dispose(obj.Entries(key));
            end
            obj.Entries(key) = struct( ...
                "Id", string(id), ...
                "Value", value, "Cleanup", cleanup);
        end

        function value = get(obj, id)
            key = char(string(id));
            if ~isKey(obj.Entries, key)
                value = [];
                return;
            end
            entry = obj.Entries(key);
            value = entry.Value;
        end

        function remove(obj, id)
            key = char(string(id));
            if ~isKey(obj.Entries, key)
                return;
            end
            entry = obj.Entries(key);
            remove(obj.Entries, key);
            obj.dispose(entry);
        end

        function clearAll(obj)
            keys = string(obj.Entries.keys);
            failures = cell(1, numel(keys));
            failureCount = 0;
            for key = keys
                entry = obj.Entries(char(key));
                remove(obj.Entries, char(key));
                try
                    obj.dispose(entry);
                catch cause
                    failureCount = failureCount + 1;
                    failures{failureCount} = cause;
                end
            end
            failures = failures(1:failureCount);
            if ~isempty(failures)
                failure = MException( ...
                    "labkit:app:runtime:ResourceCleanupFailed", ...
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
