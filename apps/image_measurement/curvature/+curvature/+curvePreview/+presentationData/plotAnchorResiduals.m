% App-owned curvature residual plotting helper. Expected caller:
% labkit_CurvatureMeasurement_app overlay rendering. Inputs are axes, anchor
% points, and a fit result struct. Draws residual segments and has no other side
% effects.
function plotAnchorResiduals(ax, points, fit)
%PLOTANCHORRESIDUALS Plot anchor-to-circle residual segments.

    dx = points(:, 1) - fit.xc_px;
    dy = points(:, 2) - fit.yc_px;
    radii = hypot(dx, dy);
    valid = isfinite(radii) & radii > eps;
    if ~any(valid)
        return;
    end

    circleX = fit.xc_px + fit.R_px .* dx(valid) ./ radii(valid);
    circleY = fit.yc_px + fit.R_px .* dy(valid) ./ radii(valid);
    anchorX = points(valid, 1);
    anchorY = points(valid, 2);
    xSegments = [anchorX.'; circleX.'; NaN(1, numel(circleX))];
    ySegments = [anchorY.'; circleY.'; NaN(1, numel(circleY))];
    plot(ax, xSegments(:), ySegments(:), '--', ...
        'Color', [1 0.9 0], ...
        'LineWidth', 1.2, ...
        'HitTest', 'off', ...
        'PickableParts', 'none', ...
        'DisplayName', 'anchor residuals');
end
