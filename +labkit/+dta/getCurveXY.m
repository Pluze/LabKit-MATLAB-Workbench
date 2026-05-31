function [x, y, xname, yname] = getCurveXY(curve, xsel, ysel)
%GETCURVEXY Return exact-name X/Y vectors from a parsed CV/CT curve.
%
% Inputs:
%   curve - parsed curve struct with headers and data fields.
%   xsel, ysel - exact header names to extract.
%
% Output:
%   x, y - numeric vectors, or [] when either header is absent.
%   xname, yname - returned header names, or '' when absent.

    x = [];
    y = [];
    xname = '';
    yname = '';

    if ~isfield(curve, 'headers') || ~isfield(curve, 'data') ...
            || isempty(curve.headers) || isempty(curve.data)
        return;
    end

    ix = find(strcmp(curve.headers, xsel), 1);
    iy = find(strcmp(curve.headers, ysel), 1);
    if isempty(ix) || isempty(iy)
        return;
    end

    x = curve.data(:, ix);
    y = curve.data(:, iy);

    good = ~(isnan(x) | isnan(y));
    x = x(good);
    y = y(good);

    xname = curve.headers{ix};
    yname = curve.headers{iy};
end
