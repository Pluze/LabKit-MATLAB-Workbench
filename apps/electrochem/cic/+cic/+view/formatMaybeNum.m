% Expected caller: CIC app runner. Inputs are a numeric value and sprintf format.
% Output is the stable UI text for finite or missing values. No side effects.

function s = formatMaybeNum(v, fmt)
    if isfinite(v)
        s = sprintf(fmt, v);
    else
        s = 'NaN';
    end
end
