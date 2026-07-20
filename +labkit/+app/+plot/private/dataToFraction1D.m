% Private UI plot axes helper. Expected caller: coordinate conversion helpers.
% Inputs are data values plus one axes dimension's limits, scale, and direction.
% Output is the normalized fraction along that dimension.
function fraction = dataToFraction1D(values, limits, scaleMode, direction)
    values = double(values);
    limits = double(limits);
    if strcmp(char(string(scaleMode)), 'log')
        values(values <= 0) = NaN;
        limits(limits <= 0) = NaN;
        values = log10(values);
        limits = log10(limits);
    end
    span = limits(2) - limits(1);
    if ~isfinite(span) || span == 0
        fraction = NaN(size(values));
    else
        fraction = (values - limits(1)) ./ span;
    end
    if strcmp(char(string(direction)), 'reverse')
        fraction = 1 - fraction;
    end
end
