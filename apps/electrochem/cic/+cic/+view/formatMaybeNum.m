% Expected caller: CIC app runner. Inputs are a numeric value and sprintf format.
% Output is the stable UI text for finite or missing values. No side effects.
function txt = formatMaybeNum(value, fmt)
    txt = cic.core.dispatch("formatMaybeNum", value, fmt);
end
