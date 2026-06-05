% Expected caller: VT resistance app runner. Input is a duration in seconds.
% Output is the stable microsecond display text. No side effects.

function txt = formatDurationUs(dt_s)
    if ~isscalar(dt_s) || ~isfinite(dt_s) || dt_s < 0
        txt = '-';
    else
        txt = sprintf('%.3f us', 1e6 * dt_s);
    end
end
