% Expected callers: Video Marker lifecycle, actions, presenter, and exports.
% Input is a portable source-record array and semantic id. Output is the
% current resolved original path or an empty string.
function pathValue = pathForId(sources, id)
    pathValue = "";
    if isempty(sources)
        return;
    end
    match = find(string({sources.id}) == string(id), 1, 'first');
    if isempty(match) || ~isfield(sources(match), 'reference') || ...
            ~isstruct(sources(match).reference) || ...
            ~isfield(sources(match).reference, 'originalPath')
        return;
    end
    pathValue = string(sources(match).reference.originalPath);
end
