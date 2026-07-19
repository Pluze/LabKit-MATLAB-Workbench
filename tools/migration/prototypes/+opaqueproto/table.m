function result = table(presentation, target, model)
    arguments
        presentation (1, 1) function_handle
        target (1, 1) string
        model
    end
    result = appendOperation( ...
        presentation, "table", target, model, "");
end
