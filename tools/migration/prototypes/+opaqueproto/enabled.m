function result = enabled(presentation, target, value)
    arguments
        presentation (1, 1) function_handle
        target (1, 1) string
        value (1, 1) logical
    end
    result = appendOperation( ...
        presentation, "enabled", target, value, "");
end
