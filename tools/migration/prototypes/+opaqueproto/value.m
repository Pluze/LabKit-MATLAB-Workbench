function result = value(presentation, target, newValue)
    arguments
        presentation (1, 1) function_handle
        target (1, 1) string
        newValue
    end
    result = appendOperation( ...
        presentation, "value", target, newValue, "");
end
