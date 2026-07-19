classdef (Sealed) Command
    %COMMAND Disposable callback-role contract prototype.
    %   Command(id, callback, Role=role) validates the declared callback
    %   signature before application compilation.
    properties (SetAccess = immutable)
        Id (1, 1) string
        Role (1, 1) string
        Callback
    end

    methods
        function obj = Command(id, callback, options)
            arguments
                id (1, 1) string {mustBeValidId}
                callback (1, 1) function_handle
                options.Role (1, 1) string {mustBeRole} = "invoke"
            end
            expected = 2 + (options.Role ~= "invoke");
            actualInputs = nargin(callback);
            actualOutputs = nargout(callback);
            if actualInputs ~= expected || actualOutputs ~= 1
                error("prototype:ui:CallbackRoleMismatch", ...
                    "Command %s role %s requires %d inputs and one output.", ...
                    id, options.Role, expected);
            end
            obj.Id = id;
            obj.Role = options.Role;
            obj.Callback = callback;
        end
    end
end

function mustBeValidId(value)
    if strlength(value) == 0 || ~isvarname(char(value))
        error("prototype:ui:InvalidValue", "Invalid command ID: %s", value);
    end
end

function mustBeRole(value)
    allowed = ["invoke", "value", "tableEdit", "selection", "interaction"];
    if ~any(value == allowed)
        error("prototype:ui:InvalidValue", ...
            "Unsupported command role: %s", value);
    end
end
