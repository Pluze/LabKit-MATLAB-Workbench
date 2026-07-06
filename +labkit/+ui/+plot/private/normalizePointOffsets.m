% Private UI plot axes helper. Expected caller: offset coordinate helpers.
% Inputs are a 1-by-2 or N-by-2 offset matrix and point count. Output is an
% N-by-2 double offset matrix.
function offsets = normalizePointOffsets(offsets, count)
    offsets = validatePointPairs(offsets, 'offsetFraction');
    if size(offsets, 1) == 1 && count > 1
        offsets = repmat(offsets, count, 1);
    end
    if size(offsets, 1) ~= count
        error('labkit:ui:plot:InvalidPointOffsets', ...
            'offsetFraction must have one row or match the number of points.');
    end
end
