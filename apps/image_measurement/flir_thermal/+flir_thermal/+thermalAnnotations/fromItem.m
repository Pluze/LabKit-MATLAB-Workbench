% Convert one decoded FLIR item into its lightweight durable annotation.
function annotation = fromItem(item, sourceId)
    annotation = flir_thermal.thermalAnnotations.empty();
    annotation.sourceId = string(sourceId);
    fields = fieldnames(annotation);
    for k = 1:numel(fields)
        field = fields{k};
        if string(field) ~= "sourceId" && isfield(item, field)
            annotation.(field) = item.(field);
        end
    end
end
