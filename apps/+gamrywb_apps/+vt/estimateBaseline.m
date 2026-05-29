function [v, window_s] = estimateBaseline(t, y, t1, t2, fallbackValue)
%ESTIMATEBASELINE Estimate baseline as a window median with fallback.

    if nargin < 5
        fallbackValue = NaN;
    end

    v = gamrywb.util.medianInWindow(t, y, t1, t2);
    if ~isfinite(v)
        v = fallbackValue;
    end
    window_s = max(0, t2 - t1);
end
