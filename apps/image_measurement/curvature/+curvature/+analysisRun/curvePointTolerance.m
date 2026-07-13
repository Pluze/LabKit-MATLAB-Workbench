% App-owned numeric policy helper. Expected callers are curvature fitting and
% curve-length analysis. Output is the pixel-distance tolerance used to merge
% adjacent duplicate points. No side effects.
function tolerancePx = curvePointTolerance()
%CURVEPOINTTOLERANCE Return the shared duplicate-point tolerance in pixels.

    % Constant: 1e-9 pixels removes only floating-point duplicate coordinates
    % while preserving every physically distinct traced point.
    tolerancePx = 1e-9;
end
