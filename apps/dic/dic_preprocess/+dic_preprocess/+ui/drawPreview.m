% Expected caller: DIC preprocess action table. Inputs are the app UI handle struct
% and a preview request from dic_preprocess.view.previewRequest. Side effects:
% clears and redraws the preview axes.

function drawPreview(ui, request)
%DRAWPREVIEW Render a prepared DIC preprocess preview request.

    labkit.ui.view.resetAxes(ui, 'previewAxes', 'Reference', true, 'reference');
    labkit.ui.view.resetAxes(ui, 'previewAxes', 'Current Preview', true, 'current');
    if ~isempty(request.topImage)
        dic_preprocess.ui.showImage(ui, 'reference', ...
            request.topImage, request.topTitle);
    end
    if ~isempty(request.bottomImage)
        dic_preprocess.ui.showImage(ui, 'current', ...
            request.bottomImage, request.bottomTitle);
    end
end
