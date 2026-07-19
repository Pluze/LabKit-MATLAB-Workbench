function value = scaleReference(options)
    arguments
        options.Target (1, 1) string
        options.Points (:, 2) double = zeros(0, 2)
        options.Changed (1, 1) function_handle
    end
    readToken(options.Changed, "command");
    value = makeToken("interaction", struct( ...
        "Kind", "scaleReference", "Target", options.Target, ...
        "Value", options.Points, "Changed", options.Changed));
end
