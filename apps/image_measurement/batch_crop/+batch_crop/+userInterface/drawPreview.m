% App-owned preview drawing helper. Expected caller: batch_crop/run refresh.
% Inputs are prepared crop geometry, placement, crop size, UI tool handles,
% and optional captured view state. Side effects are limited to redrawing the
% preview axes and refreshing the crop/scale interaction backgrounds.
function handles = drawPreview(ui, previewAxes, geometry, placement, item, cropSize, tools, viewState)
    if nargin < 8
        viewState = [];
    end

    render = batch_crop.userInterface.previewRenderData(geometry, placement);
    hImage = labkit.ui.plot.image(ui, 'preview', render.imageData, ...
        "title", "Padded rotation preview + fixed crop", ...
        "axis", "crop", ...
        "options", struct("xData", render.xData, "yData", render.yData));
    hold(previewAxes, 'on');
    [position, hLineX, hLineY] = drawCropOverlay(previewAxes, geometry, ...
        placement, item.centerXY, cropSize);
    hold(previewAxes, 'off');

    tools.scaleTool.setBackground(hImage);
    tools.scaleTool.setImageSize(size(item.image));
    tools.scaleTool.refresh();
    tools.cropEditor.setBounds([placement.xData, placement.yData]);
    tools.cropEditor.setPosition(position);
    tools.cropEditor.setBackground(hImage);
    tools.cropEditor.activateIfAvailable();
    cropGraphics = tools.cropEditor.graphics();
    hRect = cropGraphics(1);
    batch_crop.userInterface.restorePreviewView(previewAxes, viewState, geometry, placement);

    handles = struct('image', hImage, 'rect', hRect, ...
        'centerX', hLineX, 'centerY', hLineY);
end

function [position, hLineX, hLineY] = drawCropOverlay(previewAxes, geometry, ...
        placement, centerXY, cropSize)
    previewScale = batch_crop.cropGeometry.geometryScale(geometry);
    cropWidth = max(1, double(cropSize(1)) * previewScale);
    cropHeight = max(1, double(cropSize(2)) * previewScale);
    canvasCenterXY = batch_crop.cropGeometry.originalToCanvas(geometry, centerXY) + ...
        placement.offset;
    colStart = round(canvasCenterXY(1) - (cropWidth - 1) / 2);
    rowStart = round(canvasCenterXY(2) - (cropHeight - 1) / 2);
    position = [colStart - 0.5, rowStart - 0.5, cropWidth, cropHeight];
    hLineX = plot(previewAxes, ...
        [canvasCenterXY(1) - 16, canvasCenterXY(1) + 16], ...
        [canvasCenterXY(2), canvasCenterXY(2)], ...
        'Color', [0 0.85 1], ...
        'LineWidth', 1.25, 'HitTest', 'off', 'PickableParts', 'none');
    hLineY = plot(previewAxes, ...
        [canvasCenterXY(1), canvasCenterXY(1)], ...
        [canvasCenterXY(2) - 16, canvasCenterXY(2) + 16], ...
        'Color', [0 0.85 1], ...
        'LineWidth', 1.25, 'HitTest', 'off', 'PickableParts', 'none');
end
