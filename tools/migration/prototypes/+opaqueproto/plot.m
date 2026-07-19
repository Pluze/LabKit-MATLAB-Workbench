function result = plot(presentation, target, renderer, model)
    arguments
        presentation (1, 1) function_handle
        target (1, 1) string
        renderer (1, 1) string
        model
    end
    result = appendOperation( ...
        presentation, "plot", target, model, renderer);
end
