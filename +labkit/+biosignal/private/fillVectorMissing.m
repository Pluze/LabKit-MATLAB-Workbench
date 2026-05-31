function x = fillVectorMissing(x)
%FILLVECTORMISSING Fill missing numeric samples for private readers/filters.
%
% Inputs:
%   x - numeric/logical vector or array; values are reshaped to a column.
%
% Output:
%   x - double column vector. Finite samples are preserved, missing or
%       non-finite samples are linearly interpolated/extrapolated, and an
%       all-missing vector becomes zeros.
%
% Notes:
%   Uses interp1 only, so the biosignal facade does not depend on toolbox
%   fillmissing behavior.

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
