% Expected caller: Image Enhance runner. Inputs are a scalar-ish UI value
% and numeric limits. Output is a finite scalar clamped to the limits.
function value = clampValue(value, limits)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = limits(1);
    end
    value = min(max(value, limits(1)), limits(2));
end
