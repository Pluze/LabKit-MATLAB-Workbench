function value = preview(id)
    arguments
        id (1, 1) string {mustBeValidId}
    end
    value = makeToken("target", struct( ...
        "Id", id, "TargetKind", "preview", ...
        "Capabilities", ["plot", "interaction", "visible"]));
end

function mustBeValidId(value)
    if strlength(value) == 0 || ~isvarname(char(value))
        error("prototype:ui:InvalidValue", "Invalid target ID: %s", value);
    end
end
