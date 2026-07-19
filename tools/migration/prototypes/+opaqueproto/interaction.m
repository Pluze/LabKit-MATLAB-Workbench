function result = interaction(presentation, target, interactionValue)
    arguments
        presentation (1, 1) function_handle
        target (1, 1) string
        interactionValue (1, 1) function_handle
    end
    readToken(interactionValue, "interaction");
    result = appendOperation( ...
        presentation, "interaction", target, interactionValue, "");
end
