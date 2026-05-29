function v = interp1Safe(x, y, xq)
%INTERP1SAFE Linear interpolation with NaN and nearest-point fallback.

    if numel(x) < 2 || any(~isfinite([x(:); y(:)]))
        v = NaN;
        return;
    end

    try
        v = interp1(x, y, xq, 'linear', 'extrap');
    catch
        idx = gamrywb.util.nearestIndex(x, xq);
        v = y(idx);
    end
end
