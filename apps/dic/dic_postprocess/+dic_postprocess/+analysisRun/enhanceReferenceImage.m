% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are reference image data and overlay options. Output is normalized,
% enhanced RGB image data. Side effects: none.
function img = enhanceReferenceImage(referenceImage, opts)
    img = localIm2double(referenceImage);
    if ismatrix(img)
        img = repmat(img, [1 1 3]);
    end
    gains = reshape(opts.rgbGain, 1, 1, 3);
    img = img .* gains;
    img = dic_postprocess.analysisRun.clamp01(img);

    hsvImage = rgb2hsv(img);
    hsvImage(:, :, 2) = dic_postprocess.analysisRun.clamp01( ...
        hsvImage(:, :, 2) .* opts.saturation);
    img = hsv2rgb(hsvImage);

    img = (img - 0.5) .* opts.contrast + 0.5 + opts.brightness;
    img = dic_postprocess.analysisRun.clamp01(img);
    img = img .^ opts.gamma;
    img = dic_postprocess.analysisRun.clamp01(img);
end

function imageOut = localIm2double(imageIn)
    if isfloat(imageIn)
        imageOut = double(imageIn);
    elseif isa(imageIn, 'uint8')
        imageOut = double(imageIn) ./ double(intmax('uint8'));
    elseif isa(imageIn, 'uint16')
        imageOut = double(imageIn) ./ double(intmax('uint16'));
    elseif isa(imageIn, 'int16')
        imageOut = (double(imageIn) - double(intmin('int16'))) ./ ...
            double(intmax('int16') - intmin('int16'));
    else
        imageOut = double(imageIn);
    end
end
