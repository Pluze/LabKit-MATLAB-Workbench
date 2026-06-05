% Expected caller: VT resistance app runner. Input is a duration in seconds.
% Output is the stable microsecond display text. No side effects.
function txt = formatDurationUs(value)
    txt = vt_resistance.core.dispatch("formatDurationUs", value);
end
