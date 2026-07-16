% Expected caller: Image Enhance session creation and preview rebuild actions.
% Inputs are a downsampled source, source-coordinate steps/ROI, and preview
% scale. Output applies the full pipeline in preview coordinates.
function imageOut = previewResult(sourceImage, steps, whiteRoi, scale)
    scale = max(eps, double(scale));
    for k = 1:numel(steps)
        kind = lower(regexprep(char(string(steps(k).kind)), ...
            '[^a-zA-Z0-9]', ''));
        if any(strcmp(kind, {'localcontrast', 'sharpen'}))
            steps(k).secondary = steps(k).secondary .* scale;
        end
    end
    context = image_enhance.appState.emptyItem();
    context.whiteRoi = double(whiteRoi) .* scale;
    processed = image_enhance.analysisRun.applyPipeline( ...
        {sourceImage}, steps, {context});
    imageOut = processed{1};
end
