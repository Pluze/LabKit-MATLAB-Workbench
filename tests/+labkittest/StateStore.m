classdef StateStore
    %STATESTORE Process-local test-run state shared with callback functions.

    methods (Static)
        function set(key, value)
            labkittest.StateStore.manage("set", string(key), value);
        end

        function value = get(key, defaultValue)
            if nargin < 2
                defaultValue = [];
            end
            value = labkittest.StateStore.manage( ...
                "get", string(key), defaultValue);
        end

        function reset(varargin)
            keys = string(varargin);
            if isempty(keys)
                labkittest.StateStore.manage("clear", "", []);
                return;
            end
            for key = keys
                labkittest.StateStore.manage("remove", key, []);
            end
        end
    end

    methods (Static, Access = private)
        function output = manage(action, key, value)
            persistent values
            if isempty(values)
                values = containers.Map("KeyType", "char", "ValueType", "any");
            end
            output = [];
            name = char(key);
            switch action
                case "set"
                    values(name) = value;
                case "get"
                    if isKey(values, name)
                        output = values(name);
                    else
                        output = value;
                    end
                case "remove"
                    if isKey(values, name)
                        remove(values, name);
                    end
                case "clear"
                    values = containers.Map("KeyType", "char", "ValueType", "any");
                otherwise
                    error("labkit:test:UnknownStateStoreAction", ...
                        "Unknown test-state action: %s", action);
            end
        end
    end
end
