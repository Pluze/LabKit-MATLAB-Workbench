% Apply source-coordinate steps and ROI to a downsampled preview while scaling
% pixel-radius parameters into preview coordinates.
function imageOut = previewResult(sourceImage, steps, whiteRoi, scale)
    scale = max(eps, double(scale));
    for k = 1:numel(steps)
        kind = regexprep(char(string(steps(k).kind)), ...
            '[^a-zA-Z0-9]', '');
        if any(strcmpi(kind, {'localcontrast', 'sharpen'}))
            steps(k).secondary = steps(k).secondary .* scale;
        end
    end
    context = image_enhance.sourceFiles.emptyItem();
    context.whiteRoi = double(whiteRoi) .* scale;
    processed = image_enhance.analysisRun.applyPipeline( ...
        {sourceImage}, steps, {context});
    imageOut = processed{1};
end
