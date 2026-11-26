function indices = selectedCurveIndices(count, opts)
    indices = 1:count;
    if logicalScalar(opts.ignoreEdgeCycles) && count > 0
        indices = indices(indices ~= 1 & indices ~= count);
    end
end

function tf = logicalScalar(value)
    if islogical(value) || isnumeric(value)
        tf = isscalar(value) && logical(value);
    else
        tf = any(strcmpi(string(value), ["true", "on", "1", "yes"]));
    end
end
