% App-private image measurement helper. Expected caller: owning app callbacks
% and temporary compatibility tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function [x, y] = removeDuplicateNeighbors(x, y, tol)
%REMOVEDUPLICATENEIGHBORS Remove consecutive duplicate curve points.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app private numeric helpers.
%
% Inputs/outputs:
%   Pixel vectors and a distance tolerance. Returns column vectors with
%   consecutive near-duplicates removed.
%
% Side effects:
%   None.

    x = x(:);
    y = y(:);
    if isempty(x)
        return;
    end
    keep = [true; hypot(diff(x), diff(y)) > tol];
    x = x(keep);
    y = y(keep);
end
