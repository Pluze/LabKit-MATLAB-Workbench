% App-owned curvature display helper. Expected caller:
% labkit_CurvatureMeasurement_app summary rendering. Input is a value to render.
% Output is '-' for empty values or char(value) otherwise.
function s = emptyDash(value)
%EMPTYDASH Render an empty app value as a dash.

    if strlength(string(value)) == 0
        s = '-';
    else
        s = char(value);
    end
end
