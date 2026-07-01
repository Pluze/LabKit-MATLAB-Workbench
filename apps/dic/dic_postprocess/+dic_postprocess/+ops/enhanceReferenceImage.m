% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are reference image data and overlay options. Output is normalized,
% enhanced RGB image data. Side effects: none.
function img = enhanceReferenceImage(referenceImage, opts)
    img = im2double(referenceImage);
    if ndims(img) == 2
        img = repmat(img, [1 1 3]);
    end
    gains = reshape(opts.rgbGain, 1, 1, 3);
    img = img .* gains;
    img = dic_postprocess.ops.clamp01(img);

    hsvImage = rgb2hsv(img);
    hsvImage(:, :, 2) = dic_postprocess.ops.clamp01( ...
        hsvImage(:, :, 2) .* opts.saturation);
    img = hsv2rgb(hsvImage);

    img = (img - 0.5) .* opts.contrast + 0.5 + opts.brightness;
    img = dic_postprocess.ops.clamp01(img);
    img = img .^ opts.gamma;
    img = dic_postprocess.ops.clamp01(img);
end
