% DIC Postprocess ops helper. Expected caller: app-owned overlay helpers.
% Inputs are a 2-D numeric map and Gaussian sigma. Output is smoothed data
% computed with conv2 so Image Processing Toolbox is not required. Side
% effects: none.
function imageOut = gaussianSmooth(imageIn, sigma)
    sigma = double(sigma);
    if ~isfinite(sigma) || sigma <= 0
        imageOut = imageIn;
        return;
    end
    radius = max(1, ceil(3 * sigma));
    x = -radius:radius;
    kernel = exp(-(x .^ 2) ./ (2 * sigma ^ 2));
    kernel = kernel ./ sum(kernel);
    imageOut = conv2(conv2(double(imageIn), kernel, 'same'), kernel.', 'same');
end
