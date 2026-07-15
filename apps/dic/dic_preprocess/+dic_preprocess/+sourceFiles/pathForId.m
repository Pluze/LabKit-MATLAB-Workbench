% Expected callers: DIC Preprocess actions and presentation. Inputs are the
% durable source records and semantic source id. Output is the current resolved
% path or an empty string.
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
