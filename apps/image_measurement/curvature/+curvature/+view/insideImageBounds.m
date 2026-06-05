% App-owned curvature axes hit-test helper. Expected caller:
% labkit_CurvatureMeasurement_app scroll handling. Inputs are x/y points and an
% image size. Output is a scalar logical. This helper has no side effects.
function tf = insideImageBounds(x, y, imageSize)
%INSIDEIMAGEBOUNDS Return true when a point is inside image bounds.

    tf = isfinite(x) && isfinite(y) && ...
        x >= 0.5 && y >= 0.5 && ...
        x <= imageSize(2) + 0.5 && y <= imageSize(1) + 0.5;
end
