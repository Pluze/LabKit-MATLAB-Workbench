% App-owned implementation for video_marker.videoPreview.draw within the video_marker product workflow.
function draw(axesById, model)
%DRAW Render one frame with display-only skeleton and scale overlays.
ax = axesById.video;
view = captureView(ax, model.image);
labkit.app.plot.clearAxes(ax);
if isempty(model.image)
    title(ax, model.title);
    box(ax, "on");
    return
end
if ndims(model.image) == 2
    imagesc(ax, model.image);
    colormap(ax, gray(256));
else
    image(ax, model.image);
end
axis(ax, "image");
ax.YDir = "reverse";
hold(ax, "on");
for k = 1:size(model.skeleton.edges, 1)
    edge = model.skeleton.edges(k, :);
    if all(edge <= size(model.points, 1))
        plot(ax, model.points(edge, 1), model.points(edge, 2), "-", ...
            Color=[0.1 0.65 1], LineWidth=1.5, ...
            HitTest="off", PickableParts="none");
    end
end
for k = 1:size(model.points, 1)
    text(ax, model.points(k, 1) + 4, model.points(k, 2) + 4, ...
        string(model.skeleton.pointNames(k)), Color=[1 1 1], ...
        FontWeight="bold", Interpreter="none", ...
        HitTest="off", PickableParts="none");
end
if ~isempty(model.scaleBar)
    plot(ax, model.scaleBar.line(:, 1), model.scaleBar.line(:, 2), "-", ...
        Color=model.scaleBar.color, LineWidth=3, ...
        HitTest="off", PickableParts="none");
    text(ax, model.scaleBar.labelPosition(1), ...
        model.scaleBar.labelPosition(2), model.scaleBar.label, ...
        Color=model.scaleBar.color, FontWeight="bold", ...
        HorizontalAlignment="center", ...
        VerticalAlignment=char(model.scaleBar.verticalAlignment), ...
        HitTest="off", PickableParts="none");
end
hold(ax, "off");
title(ax, model.title);
xlabel(ax, "");
ylabel(ax, "");
box(ax, "on");
restoreView(ax, view);
end

function view = captureView(ax, imageData)
view = struct("preserve", false, "x", [], "y", []);
images = findobj(ax, Type="image");
if isempty(images) || isempty(imageData)
    return
end
oldSize = size(images(1).CData);
newSize = size(imageData);
if numel(oldSize) >= 2 && numel(newSize) >= 2 && ...
        isequal(oldSize(1:2), newSize(1:2))
    view = struct("preserve", true, "x", ax.XLim, "y", ax.YLim);
end
end

function restoreView(ax, view)
if view.preserve
    ax.XLim = view.x;
    ax.YLim = view.y;
end
end
