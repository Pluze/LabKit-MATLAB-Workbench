function draw(axesById, model)
%DRAW Render the image, curve, circle fit, residuals, and scale bar.
ax = axesById.image;
view = captureImageView(ax, model.imageData);
labkit.app.plot.clearAxes(ax);
if isempty(model.imageData)
    title(ax, "Image + Circle Fit");
    box(ax, "on");
    return
end
if ndims(model.imageData) == 2
    imagesc(ax, model.imageData, ...
        HitTest="off", PickableParts="none");
    colormap(ax, gray(256));
else
    image(ax, model.imageData, ...
        HitTest="off", PickableParts="none");
end
axis(ax, "image");
ax.YDir = "reverse";
hold(ax, "on");
curvature.curvePreview.presentationData.plotStaticCurveAnchors( ...
    ax, model.points, model.curve, model.fit, model.showDensePoints);
drawFit(ax, model.fit);
drawScaleBar(ax, model.scaleBar);
hold(ax, "off");
title(ax, fitTitle(model.fit));
box(ax, "on");
restoreImageView(ax, view);
end

function drawFit(ax, fit)
if ~fit.ok
    return
end
angle = linspace(-pi, pi, 600);
plot(ax, fit.xc_px + fit.R_px .* cos(angle), ...
    fit.yc_px + fit.R_px .* sin(angle), ...
    "r-", LineWidth=2, HitTest="off", PickableParts="none");
plot(ax, fit.xc_px, fit.yc_px, ...
    "ro", MarkerFaceColor="r", ...
    HitTest="off", PickableParts="none");
end

function drawScaleBar(ax, scaleBar)
if isempty(scaleBar)
    return
end
plot(ax, scaleBar.line(:, 1), scaleBar.line(:, 2), "-", ...
    Color=scaleBar.color, LineWidth=3, ...
    HitTest="off", PickableParts="none");
text(ax, scaleBar.labelPosition(1), scaleBar.labelPosition(2), ...
    scaleBar.label, Color=scaleBar.color, FontWeight="bold", ...
    HorizontalAlignment="center", ...
    VerticalAlignment=char(scaleBar.verticalAlignment), ...
    HitTest="off", PickableParts="none");
end

function value = fitTitle(fit)
value = "Image + Circle Fit";
if fit.ok
    value = sprintf( ...
        "R = %.4g %s, curvature = %.4g %s, RMSE = %.3g %s", ...
        fit.R_show, fit.unitLen, fit.kappa_show, fit.unitK, ...
        fit.rmse_show, fit.unitLen);
end
end

function view = captureImageView(ax, imageData)
view = struct("preserve", false, "xLimits", [], "yLimits", []);
images = findobj(ax, "Type", "image");
if isempty(images) || isempty(imageData)
    return
end
previousSize = size(images(1).CData);
nextSize = size(imageData);
if numel(previousSize) < 2 || numel(nextSize) < 2 || ...
        ~isequal(previousSize(1:2), nextSize(1:2))
    return
end
view = struct("preserve", true, ...
    "xLimits", double(ax.XLim), "yLimits", double(ax.YLim));
end

function restoreImageView(ax, view)
if view.preserve
    ax.XLim = view.xLimits;
    ax.YLim = view.yLimits;
end
end
