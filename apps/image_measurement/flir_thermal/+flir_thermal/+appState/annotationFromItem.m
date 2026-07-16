% Expected caller: FLIR V2 actions. Inputs are a decoded thermal item and
% canonical source ID. Output is the lightweight durable item annotation.
function annotation = annotationFromItem(item, sourceId)
    annotation = flir_thermal.appState.emptyAnnotation();
    annotation.sourceId = string(sourceId);
    fields = fieldnames(annotation);
    for k = 1:numel(fields)
        field = fields{k};
        if string(field) ~= "sourceId" && isfield(item, field)
            annotation.(field) = item.(field);
        end
    end
end
