% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function img = enhanceReferenceImage(referenceImage, opts)
    img = ensureRgb(im2double(referenceImage));
    gains = reshape(opts.rgbGain, 1, 1, 3);
    img = img .* gains;
    img = clamp01(img);

    hsvImage = rgb2hsv(img);
    hsvImage(:, :, 2) = clamp01(hsvImage(:, :, 2) .* opts.saturation);
    img = hsv2rgb(hsvImage);

    img = (img - 0.5) .* opts.contrast + 0.5 + opts.brightness;
    img = clamp01(img);
    img = img .^ opts.gamma;
    img = clamp01(img);
end
