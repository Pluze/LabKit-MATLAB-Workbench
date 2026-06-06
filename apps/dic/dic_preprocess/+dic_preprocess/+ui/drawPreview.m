% Expected caller: DIC preprocess runner. Inputs are the app UI handle struct
% and a preview request from dic_preprocess.view.previewRequest. Side effects:
% clears and redraws the preview axes.

function drawPreview(ui, request)
%DRAWPREVIEW Render a prepared DIC preprocess preview request.

    labkit.ui.view.draw(ui.topAxes, 'reset', 'Reference', true);
    labkit.ui.view.draw(ui.bottomAxes, 'reset', 'Current Preview', true);
    if ~isempty(request.topImage)
        dic_preprocess.ui.showImage(ui.topAxes, request.topImage, request.topTitle);
    end
    if ~isempty(request.bottomImage)
        dic_preprocess.ui.showImage(ui.bottomAxes, ...
            request.bottomImage, request.bottomTitle);
    end
end
