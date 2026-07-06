% Private UI plot axes helper. Expected caller: coordinate conversion helpers.
% Inputs are numeric point pairs and a diagnostic name. Output is an N-by-2
% double matrix.
function points = validatePointPairs(points, name)
    if ~(isnumeric(points) && ismatrix(points) && size(points, 2) == 2)
        error('labkit:ui:plot:InvalidPointPairs', ...
            '%s must be an N-by-2 numeric matrix.', char(string(name)));
    end
    points = double(points);
end
