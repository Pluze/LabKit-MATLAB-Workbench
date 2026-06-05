% Expected caller: CIC app plotting helpers. Inputs are vectors x/y and query
% points. Output mirrors the app-owned safe interpolation helper. No side effects.

function v = interp1Safe(x, y, xq)
    if numel(x) < 2 || any(~isfinite([x(:); y(:)]))
        v = NaN;
        return;
    end

    try
        v = interp1(x, y, xq, 'linear', 'extrap');
    catch
        idx = nearestIndex(x, xq);
        v = y(idx);
    end
end

function idx = nearestIndex(x, xq)
    [~, idx] = min(abs(x - xq));
end
