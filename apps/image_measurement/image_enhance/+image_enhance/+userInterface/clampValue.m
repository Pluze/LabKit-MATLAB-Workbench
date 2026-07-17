% Convert a scalar UI value to a finite value clamped to numeric limits.
function value = clampValue(value, limits)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = limits(1);
    end
    value = min(max(value, limits(1)), limits(2));
end
