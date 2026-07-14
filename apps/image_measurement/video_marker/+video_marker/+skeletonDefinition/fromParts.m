%FROMPARTS Build a skeleton from ordered point names and indexed edges.
% Expected caller: the visual skeleton configurator, CSV import helpers, and
% tests. Names are N-by-1 text; edges are M-by-2 1-based point indices.
function skeleton = fromParts(pointNames, edges)
    names = strtrim(string(pointNames(:)));
    if any(strlength(names) == 0)
        error('labkit_VideoMarker_app:EmptyKeypoint', ...
            'Every keypoint must have a name.');
    end
    if numel(unique(lower(names))) ~= numel(names)
        error('labkit_VideoMarker_app:DuplicateKeypoint', ...
            'Keypoint names must be unique.');
    end

    edges = double(edges);
    if isempty(edges)
        edges = zeros(0, 2);
    end
    if size(edges, 2) ~= 2 || any(~isfinite(edges(:))) || ...
            any(edges(:) ~= round(edges(:))) || ...
            any(edges(:) < 1) || any(edges(:) > numel(names))
        error('labkit_VideoMarker_app:InvalidEdge', ...
            'Connections must reference two defined keypoints.');
    end
    edges = sort(edges, 2);
    if any(edges(:, 1) == edges(:, 2))
        error('labkit_VideoMarker_app:InvalidEdge', ...
            'A connection cannot join a keypoint to itself.');
    end

    ids = matlab.lang.makeValidName(cellstr(names), "ReplacementStyle", "delete");
    ids = string(matlab.lang.makeUniqueStrings(ids));
    skeleton = struct( ...
        'schemaVersion', 1, ...
        'pointIds', ids(:), ...
        'pointNames', names, ...
        'edges', unique(edges, 'rows', 'stable'));
end
