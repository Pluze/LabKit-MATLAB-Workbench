% Expected caller: image_enhance.resultFiles.writeOutputs and tests. Input is a
% result struct array from batch export. Output is the stable CSV manifest table.
function T = buildManifest(results)

    results = results(:);
    sourceImage = strings(numel(results), 1);
    outputImage = strings(numel(results), 1);
    status = strings(numel(results), 1);
    widthPx = zeros(numel(results), 1);
    heightPx = zeros(numel(results), 1);
    stepCount = zeros(numel(results), 1);
    message = strings(numel(results), 1);

    for k = 1:numel(results)
        sourceImage(k) = results(k).sourcePath;
        outputImage(k) = results(k).outputPath;
        status(k) = results(k).status;
        widthPx(k) = results(k).widthPx;
        heightPx(k) = results(k).heightPx;
        stepCount(k) = results(k).stepCount;
        message(k) = results(k).message;
    end

    T = table(sourceImage, outputImage, status, widthPx, heightPx, ...
        stepCount, message, 'VariableNames', {'SourceImage', 'OutputImage', ...
        'Status', 'Width_px', 'Height_px', 'StepCount', 'Message'});
end
