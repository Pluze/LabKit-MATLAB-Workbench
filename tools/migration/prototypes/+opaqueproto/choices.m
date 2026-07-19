function result = choices(presentation, target, values)
    arguments
        presentation (1, 1) function_handle
        target (1, 1) string
        values
    end
    result = appendOperation( ...
        presentation, "choices", target, values, "");
end
