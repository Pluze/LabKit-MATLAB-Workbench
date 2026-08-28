function draw(axesById, model)
%DRAW Render the current image and its display-only ROI set.
drawImage(axesById.main, model);
end

function drawImage(ax, model)
labkit.app.plot.clearAxes(ax);
if isempty(model.imageData)
    title(ax, "Load an image to begin");
    box(ax, "on");
    return
end
if ismatrix(model.imageData)
    imagesc(ax, model.imageData, HitTest="off", PickableParts="none");
    colormap(ax, gray(256));
else
    image(ax, displayRgb(model.imageData), HitTest="off", PickableParts="none");
end
axis(ax, "image");
ax.YDir = "reverse";
axis(ax, "off");
hold(ax, "on");
colors = lines(max(7, numel(model.rois)));
for k = 1:numel(model.rois)
    roi = model.rois(k);
    style = "--";
    width = 1.2;
    if ismember(k, model.selectedRois)
        style = "-";
        width = 2;
    end
    curvature = [0 0];
    if roi.shape == "Circle"
        curvature = [1 1];
    end
    rectangle(ax, Position=roi.position, Curvature=curvature, ...
        EdgeColor=colors(k, :), LineStyle=style, LineWidth=width, ...
        HitTest="off", PickableParts="none");
    text(ax, roi.position(1), max(0.5, roi.position(2) - 3), ...
        roi.name, Color=colors(k, :), FontWeight="bold", ...
        BackgroundColor=[0 0 0], Margin=2, ...
        HitTest="off", PickableParts="none");
end
hold(ax, "off");
title(ax, model.imageName, Interpreter="none");
end

function rgb = displayRgb(imageData)
if isinteger(imageData)
    rgb = double(imageData) ./ double(intmax(class(imageData)));
elseif islogical(imageData)
    rgb = double(imageData);
else
    rgb = double(imageData);
    finiteValues = rgb(isfinite(rgb));
    if isempty(finiteValues)
        rgb(:) = 0;
    elseif min(finiteValues) < 0 || max(finiteValues) > 1
        low = min(finiteValues);
        high = max(finiteValues);
        if high > low
            rgb = (rgb - low) ./ (high - low);
        else
            rgb(:) = 0;
        end
    end
end
rgb(~isfinite(rgb)) = 0;
rgb = min(max(rgb, 0), 1);
end
