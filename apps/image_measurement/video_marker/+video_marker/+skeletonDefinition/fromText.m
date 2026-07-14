%FROMTEXT Build a keypoint and edge definition from user text.
% Expected caller: skeleton update action and tests. Inputs are comma/newline
% separated point names and edge tokens "name-name" or "name,name".
function skeleton = fromText(pointText, edgeText)
    names = splitTokens(pointText);
    names = names(strlength(names) > 0);
    if isempty(names)
        error('labkit_VideoMarker_app:NoKeypoints', 'Define at least one keypoint.');
    end

    nameToIndex = containers.Map(cellstr(lower(names)), num2cell(1:numel(names)));
    edgeTokens = splitTokens(edgeText);
    edges = zeros(numel(edgeTokens), 2);
    edgeCount = 0;
    for k = 1:numel(edgeTokens)
        token = string(edgeTokens(k));
        if strlength(token) == 0
            continue;
        end
        parts = split(token, ["-", ">", ":"]);
        parts = strtrim(parts);
        parts = parts(strlength(parts) > 0);
        if numel(parts) ~= 2
            error('labkit_VideoMarker_app:InvalidEdge', ...
                'Edges must use two keypoint names such as hip-knee.');
        end
        a = lookupPoint(nameToIndex, parts(1));
        b = lookupPoint(nameToIndex, parts(2));
        if a == b
            error('labkit_VideoMarker_app:InvalidEdge', 'An edge cannot connect a keypoint to itself.');
        end
        edgeCount = edgeCount + 1;
        edges(edgeCount, :) = sort([a b]);
    end
    edges = edges(1:edgeCount, :);
    edges = unique(edges, "rows", "stable");

    skeleton = video_marker.skeletonDefinition.fromParts(names, edges);
end

function tokens = splitTokens(textValue)
    textValue = string(textValue);
    textValue = replace(textValue, newline, ",");
    textValue = replace(textValue, ";", ",");
    tokens = strtrim(split(textValue, ","));
end

function idx = lookupPoint(map, name)
    key = char(lower(string(name)));
    if ~isKey(map, key)
        error('labkit_VideoMarker_app:UnknownEdgePoint', ...
            'Every edge endpoint must name a defined keypoint.');
    end
    idx = map(key);
end
