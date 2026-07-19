function token = makeToken(kind, payload)
    token = @read;

    function value = read(key)
        if string(key) ~= "__opaqueproto_compiler_read__"
            error("prototype:ui:OpaqueValue", ...
                "Opaque prototype values have no public readable fields.");
        end
        value = struct("Kind", kind, "Payload", payload);
    end
end
