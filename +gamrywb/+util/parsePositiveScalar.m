function q = parsePositiveScalar(x)
%PARSEPOSITIVESCALAR Parse a positive finite scalar, otherwise return NaN.

    if isnumeric(x)
        q = x;
    else
        x = strtrim(char(x));
        if isempty(x)
            q = NaN;
            return;
        end
        q = str2double(x);
    end

    if ~isscalar(q) || ~isfinite(q) || q <= 0
        q = NaN;
    end
end
