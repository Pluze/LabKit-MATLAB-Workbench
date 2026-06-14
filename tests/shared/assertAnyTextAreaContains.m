function assertAnyTextAreaContains(h, fig, needle, message)
%ASSERTANYTEXTAREACONTAINS Assert any GUI text area contains text.

    textAreas = h.findControlsByClass(fig, 'TextArea');
    for k = 1:numel(textAreas)
        values = string(textAreas{k}.Value);
        if any(contains(values, needle))
            return;
        end
    end
    error(message);
end
