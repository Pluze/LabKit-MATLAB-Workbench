% App-private image measurement helper. Expected caller: owning app callbacks
% and temporary compatibility tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function meanImage = boxMean2(imageData, windowSize)
%BOXMEAN2 Compute a normalized box mean for focus-stack helpers.
%
% Expected caller:
%   labkit_FocusStack_app private fusion and registration helpers.
%
% Inputs/outputs:
%   2-D numeric image and window size. Returns a same-size double local mean
%   with edge normalization matching the previous app-local implementation.
%
% Side effects:
%   None.

    windowSize = max(1, round(windowSize));
    kernel = ones(windowSize, windowSize);
    numerator = conv2(double(imageData), kernel, 'same');
    denominator = conv2(ones(size(imageData)), kernel, 'same');
    meanImage = numerator ./ max(denominator, eps);
end
