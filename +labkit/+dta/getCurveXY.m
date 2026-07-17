function [x, y, xname, yname] = getCurveXY(curve, xsel, ysel)
%GETCURVEXY Extract paired X and Y data from a parsed CV/CT curve.
%
% Usage:
%   [x, y, xname, yname] = labkit.dta.getCurveXY(curve, xsel, ysel)
%
% Description:
%   Looks up two headers using case-sensitive, exact-name matching. Rows where
%   either selected column is NaN are removed from both outputs so x and y
%   remain paired. Use getColumn when case-insensitive lookup or unfiltered
%   data is required.
%
% Inputs:
%   curve - Scalar parsed curve structure with headers and data fields.
%   xsel - Character vector or string scalar matching one header exactly.
%   ysel - Character vector or string scalar matching one header exactly.
%
% Outputs:
%   x - Numeric column vector for xsel, with paired NaN rows removed.
%   y - Numeric column vector for ysel, with paired NaN rows removed.
%   xname - Matched header character vector, or '' when lookup fails.
%   yname - Matched header character vector, or '' when lookup fails.
%
% Failure Behavior:
%   If either exact header is absent, all numeric outputs remain empty and
%   unmatched names are ''. curve must expose corresponding headers and data
%   fields; malformed structures raise the originating MATLAB error.
%
% Typical Call:
%   [voltageV, currentA, xname, yname] = ...
%       labkit.dta.getCurveXY(curve, "Vf", "Im");
%
% See also labkit.dta.getColumn,
%   labkit.dta.loadFile

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
