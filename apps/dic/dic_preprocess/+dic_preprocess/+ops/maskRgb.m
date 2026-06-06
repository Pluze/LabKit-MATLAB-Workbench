% Expected caller: DIC preprocess runner and direct unit tests. Input is a binary
% mask image. Output is the three-channel RGB mask preview. Side effects: none.

function rgb = maskRgb(maskImage)
%MASKRGB Convert a DIC preprocess mask canvas to RGB preview data.

    rgb = repmat(maskImage, [1 1 3]);
end
