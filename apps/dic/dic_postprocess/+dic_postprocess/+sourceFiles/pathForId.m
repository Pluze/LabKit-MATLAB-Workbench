% Expected callers: DIC Postprocess lifecycle, actions, and presentation.
% Inputs are durable source records and a semantic id. Output is the current
% resolved path or empty text; side effects are none.
function filepath = pathForId(sources, id)
    filepath = "";
    if isempty(sources)
        return;
    end
    match = find(string({sources.id}) == string(id), 1, 'first');
    if ~isempty(match) && isfield(sources(match), 'reference') && ...
            isfield(sources(match).reference, 'originalPath')
        filepath = string(sources(match).reference.originalPath);
    end
end
