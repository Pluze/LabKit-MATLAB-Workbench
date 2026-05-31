function x = fillVectorMissing(x)
%FILLVECTORMISSING Fill missing numeric values without toolbox-specific APIs.

    x = double(x(:));
    if isempty(x) || all(isfinite(x))
        return;
    end

    good = isfinite(x);
    if ~any(good)
        x(:) = 0;
        return;
    end

    idx = (1:numel(x)).';
    x(~good) = interp1(idx(good), x(good), idx(~good), 'linear', 'extrap');
end
