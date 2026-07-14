%REFRESHOVERLAY Redraw only the static skeleton lines and point-name labels.
% Expected caller: Video Marker preview and point-change callbacks. Inputs are
% an existing axes plus current skeleton/annotation state. The image, axes
% limits, and interaction-owned graphics/callbacks are left untouched.
function refreshOverlay(ax, skeleton, annotations, frameIndex)
    labkit.ui.plot.replaceOverlay(ax, "videoMarkerSkeleton", @drawSkeleton);

    function handles = drawSkeleton(target)
        handles = {};
        points = video_marker.frameAnnotations.framePoints(annotations, frameIndex);
        if isempty(points)
            return;
        end
        for e = 1:size(skeleton.edges, 1)
            a = skeleton.edges(e, 1);
            b = skeleton.edges(e, 2);
            if a <= size(points, 1) && b <= size(points, 1)
                handles{end + 1} = plot(target, ...
                    points([a b], 1), points([a b], 2), '-', ...
                    'Color', [0.1 0.65 1.0], 'LineWidth', 1.5, ...
                    'HitTest', 'off', 'PickableParts', 'none');
            end
        end
        for p = 1:size(points, 1)
            handles{end + 1} = text(target, ...
                points(p, 1) + 4, points(p, 2) + 4, ...
                string(skeleton.pointNames(p)), ...
                'Color', [1 1 1], 'FontWeight', 'bold', ...
                'Interpreter', 'none', 'HitTest', 'off', ...
                'PickableParts', 'none');
        end
    end
end
