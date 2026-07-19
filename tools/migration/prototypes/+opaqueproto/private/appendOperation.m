function result = appendOperation(presentation, kind, target, value, reference)
    raw = readToken(presentation, "presentation");
    if strlength(target) == 0
        error("prototype:ui:InvalidValue", ...
            "Presentation target must not be empty.");
    end
    raw.Payload.Operations{end + 1} = struct( ...
        "Kind", kind, "Target", target, "Value", value, ...
        "Reference", reference);
    result = makeToken("presentation", raw.Payload);
end
