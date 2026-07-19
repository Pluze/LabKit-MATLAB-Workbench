function value = control(id, kind)
    arguments
        id (1, 1) string {mustBeValidId}
        kind (1, 1) string {mustBeControlKind}
    end
    switch kind
        case "action"
            capabilities = ["enabled", "visible", "text"];
        case "field"
            capabilities = [ ...
                "value", "choices", "limits", "enabled", "visible", "text"];
        case "file"
            capabilities = [ ...
                "files", "selection", "status", "enabled", "visible"];
        case "table"
            capabilities = ["table", "enabled", "visible"];
        case "status"
            capabilities = ["text", "visible"];
    end
    value = makeToken("target", struct( ...
        "Id", id, "TargetKind", kind, "Capabilities", capabilities));
end

function mustBeValidId(value)
    if strlength(value) == 0 || ~isvarname(char(value))
        error("prototype:ui:InvalidValue", "Invalid target ID: %s", value);
    end
end

function mustBeControlKind(value)
    if ~any(value == ["action", "field", "file", "table", "status"])
        error("prototype:ui:InvalidValue", ...
            "Unsupported control kind: %s", value);
    end
end
