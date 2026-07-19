function value = command(id, callback, options)
    arguments
        id (1, 1) string {mustBeValidId}
        callback (1, 1) function_handle
        options.Role (1, 1) string {mustBeRole} = "invoke"
    end
    expected = 2 + (options.Role ~= "invoke");
    actual = nargin(callback);
    if actual >= 0 && actual ~= expected
        error("prototype:ui:CallbackRoleMismatch", ...
            "Command %s role %s requires %d inputs; callback has %d.", ...
            id, options.Role, expected, actual);
    end
    value = makeToken("command", struct( ...
        "Id", id, "Role", options.Role, "Callback", callback));
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
