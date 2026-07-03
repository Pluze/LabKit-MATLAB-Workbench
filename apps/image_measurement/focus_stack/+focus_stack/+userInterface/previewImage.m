% App-owned focus-stack preview normalization helper. Expected caller:
% labkit_FocusStack_app preview refresh. Input is an image array. Output is a
% double preview image with at most three channels.
function img = previewImage(img)
%PREVIEWIMAGE Normalize an image for focus-stack preview display.

    img = labkit.image.toRgbDouble(img);
    if ndims(img) == 3 && size(img, 3) > 3
        img = img(:, :, 1:3);
    end
end
