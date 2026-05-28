function m = medianInWindow(t, y, t1, t2)
%MEDIANINWINDOW Median of y where t is inside [t1, t2], omitting NaN.

    if ~isfinite(t1) || ~isfinite(t2) || t2 < t1
        m = NaN;
        return;
    end

    mask = t >= t1 & t <= t2;
    if ~any(mask)
        m = NaN;
    else
        m = median(y(mask), 'omitnan');
    end
end
