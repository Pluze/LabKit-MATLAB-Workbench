% Private UI plot axes helper. Expected caller: coordinate conversion helpers.
% Inputs are normalized fractions plus one axes dimension's limits, scale, and
% direction. Output is data coordinates along that dimension.
function values = fractionToData1D(fraction, limits, scaleMode, direction)
    fraction = double(fraction);
    limits = double(limits);
    if strcmp(char(string(direction)), 'reverse')
        fraction = 1 - fraction;
    end
    if strcmp(char(string(scaleMode)), 'log')
        if any(limits <= 0)
            values = NaN(size(fraction));
            return;
        end
        logLimits = log10(limits);
        values = 10 .^ (logLimits(1) + fraction .* diff(logLimits));
    else
        values = limits(1) + fraction .* diff(limits);
    end
end
