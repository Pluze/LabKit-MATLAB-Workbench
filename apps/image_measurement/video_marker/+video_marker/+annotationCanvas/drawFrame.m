%DRAWFRAME Draw one video frame and static annotation overlay.
% Expected caller: Video Marker UI refresh. Inputs are axes, frame image,
% skeleton, annotation struct, and 1-based frame index. Side effects are
% limited to graphics on the provided axes.
function hImage = drawFrame(ui, axesId, frameImage, skeleton, annotations, frameIndex)
    hImage = labkit.ui.plot.image(ui, axesId, frameImage, ...
        "title", sprintf('Frame %d', frameIndex), ...
        "options", struct('clearAxes', false));
    ax = ancestor(hImage, 'axes');
    hold(ax, 'on');
    points = video_marker.frameAnnotations.framePoints(annotations, frameIndex);
    drawSkeleton(ax, points, skeleton);
    hold(ax, 'off');
end

function drawSkeleton(ax, points, skeleton)
    if isempty(points)
        return;
    end
    for e = 1:size(skeleton.edges, 1)
        a = skeleton.edges(e, 1);
        b = skeleton.edges(e, 2);
        if a <= size(points, 1) && b <= size(points, 1)
            plot(ax, points([a b], 1), points([a b], 2), '-', ...
                'Color', [0.1 0.65 1.0], 'LineWidth', 1.5, ...
                'HitTest', 'off');
        end
    end
    plot(ax, points(:, 1), points(:, 2), 'o', ...
        'Color', [1.0 0.85 0.1], ...
        'MarkerFaceColor', [1.0 0.85 0.1], ...
        'MarkerSize', 6, ...
        'HitTest', 'off');
    for p = 1:size(points, 1)
        text(ax, points(p, 1) + 4, points(p, 2) + 4, string(skeleton.pointNames(p)), ...
            'Color', [1 1 1], ...
            'FontWeight', 'bold', ...
            'Interpreter', 'none', ...
            'HitTest', 'off');
    end
end
