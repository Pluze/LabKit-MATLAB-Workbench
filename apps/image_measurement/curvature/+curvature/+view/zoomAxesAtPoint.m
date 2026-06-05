% App-owned curvature axes zoom helper. Expected caller:
% labkit_CurvatureMeasurement_app scroll handling. Inputs are axes, pointer
% point, scroll count, and image size. Side effects are limited to axes limits.
function zoomAxesAtPoint(ax, x, y, scrollCount, imageSize)
%ZOOMAXESATPOINT Zoom image axes around a pointer location.

    if scrollCount == 0
        return;
    end

    fullX = [0.5, imageSize(2) + 0.5];
    fullY = [0.5, imageSize(1) + 0.5];
    zoomFactor = 1.20 ^ scrollCount;

    currentX = ax.XLim;
    currentY = ax.YLim;
    newWidth = diff(currentX) * zoomFactor;
    newHeight = diff(currentY) * zoomFactor;

    minSpan = 10;
    newWidth = min(max(newWidth, minSpan), diff(fullX));
    newHeight = min(max(newHeight, minSpan), diff(fullY));

    xFrac = (x - currentX(1)) / max(eps, diff(currentX));
    yFrac = (y - currentY(1)) / max(eps, diff(currentY));
    xFrac = min(max(xFrac, 0), 1);
    yFrac = min(max(yFrac, 0), 1);

    newX = [x - xFrac * newWidth, x + (1 - xFrac) * newWidth];
    newY = [y - yFrac * newHeight, y + (1 - yFrac) * newHeight];

    ax.XLim = curvature.view.clampLimits(newX, fullX);
    ax.YLim = curvature.view.clampLimits(newY, fullY);
end
