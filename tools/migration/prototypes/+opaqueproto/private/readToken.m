function value = readToken(token, expectedKind)
    if ~isa(token, "function_handle")
        error("prototype:ui:InvalidValue", ...
            "Expected an opaque prototype value.");
    end
    value = token("__opaqueproto_compiler_read__");
    if nargin > 1 && value.Kind ~= string(expectedKind)
        error("prototype:ui:InvalidValue", ...
            "Expected opaque %s, got %s.", expectedKind, value.Kind);
    end
end
