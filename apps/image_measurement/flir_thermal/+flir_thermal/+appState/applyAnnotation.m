% Expected callers: FLIR V2 cache loading and export. Inputs are a freshly
% decoded thermal item and optional durable annotation. Output restores only
% app-owned range and reading fields without persisting decoded matrices.
function item = applyAnnotation(item, annotation)
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
