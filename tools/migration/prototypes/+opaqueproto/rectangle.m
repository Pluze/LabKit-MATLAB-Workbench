function value = rectangle(options)
    arguments
        options.Target (1, 1) string
        options.Bounds (1, 4) double
        options.Changed (1, 1) function_handle
    end
    readToken(options.Changed, "command");
    value = makeToken("interaction", struct( ...
        "Kind", "rectangle", "Target", options.Target, ...
        "Value", options.Bounds, "Changed", options.Changed));
end
