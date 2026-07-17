% Restore one optional durable annotation onto a freshly decoded FLIR item.
function item = apply(item, annotation)
    if isempty(annotation)
        return;
    end
    fields = fieldnames(annotation);
    for k = 1:numel(fields)
        field = fields{k};
        if string(field) ~= "sourceId" && isfield(item, field)
            item.(field) = annotation.(field);
        end
    end
end
